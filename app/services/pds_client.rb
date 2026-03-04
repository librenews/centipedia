require "jwt"
require "securerandom"
require "net/http"
require "json"
require "openssl"

# DPoP-authenticated client for writing records to a user's AT Protocol PDS.
class PdsClient
  attr_reader :pds_endpoint, :dpop_nonce

  def initialize(user:, access_token:)
    require_relative "../../lib/omni_auth/atproto/key_manager"

    @user = user
    @access_token = access_token
    @pds_endpoint = extract_pds_endpoint
    @dpop_key = OmniAuth::Atproto::KeyManager.current_private_key
    @dpop_nonce = nil
  end

  # Create a Bluesky post on the user's PDS.
  #
  # @param text [String] the post content
  # @return [Hash] { success: true, uri:, cid: } or { success: false, error: }
  def create_post(text)
    return { success: false, error: "No access token available" } unless @access_token
    return { success: false, error: "Post text cannot be blank" } if text.to_s.strip.empty?

    url = "#{@pds_endpoint}/xrpc/com.atproto.repo.createRecord"

    body = {
      repo: @user.did,
      collection: "app.bsky.feed.post",
      record: {
        "$type": "app.bsky.feed.post",
        text: text,
        createdAt: Time.current.iso8601
      }
    }

    response = make_dpop_request("POST", url, body: body)

    # Handle DPoP nonce requirement: if we get 401 with a new nonce, retry once
    if response.code == "401" && response["DPoP-Nonce"]
      @dpop_nonce = response["DPoP-Nonce"]
      response = make_dpop_request("POST", url, body: body)
    end

    parse_response(response)
  rescue => e
    { success: false, error: e.message }
  end

  # Fetch the user's profile from the PDS (to get display name, avatar, etc.)
  #
  # @return [Hash] { success: true, profile: { ... } } or { success: false, error: }
  def get_profile
    return { success: false, error: "No access token available" } unless @access_token

    url = "#{@pds_endpoint}/xrpc/com.atproto.repo.getRecord?repo=#{@user.did}&collection=app.bsky.actor.profile&rkey=self"
    response = make_dpop_request("GET", url)

    if response.code == "401" && response["DPoP-Nonce"]
      @dpop_nonce = response["DPoP-Nonce"]
      response = make_dpop_request("GET", url)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      { success: true, profile: result["value"] }
    else
      { success: false, error: response.body, status: response.code.to_i }
    end
  rescue => e
    { success: false, error: e.message }
  end

  # Extract the PDS endpoint from the JWT access token's "aud" claim.
  #
  # @return [String] the PDS endpoint URL
  def extract_pds_endpoint
    return @user.pds_endpoint.presence || "https://bsky.social" unless @access_token

    decoded = JWT.decode(@access_token, nil, false)
    aud = decoded[0]["aud"]

    if aud.is_a?(String) && aud.start_with?("http")
      aud
    else
      @user.pds_endpoint.presence || "https://bsky.social"
    end
  rescue => e
    Rails.logger.warn "Failed to extract PDS from token: #{e.message}" if defined?(Rails)
    @user.pds_endpoint.presence || "https://bsky.social"
  end

  # Generate a DPoP proof JWT.
  #
  # @param http_method [String] e.g. "POST"
  # @param url [String] the full request URL
  # @return [String] the signed DPoP JWT
  def generate_dpop_token(http_method, url)
    payload = {
      jti: SecureRandom.uuid,
      htm: http_method,
      htu: url,
      iat: Time.current.to_i,
      exp: Time.current.to_i + 60
    }
    payload[:nonce] = @dpop_nonce if @dpop_nonce

    if @access_token
      token_hash = Digest::SHA256.digest(@access_token)
      payload[:ath] = Base64.urlsafe_encode64(token_hash, padding: false)
    end

    header = {
      typ: "dpop+jwt",
      jwk: dpop_public_jwk
    }

    JWT.encode(payload, @dpop_key, "ES256", header)
  end

  private

  def make_dpop_request(method, url, body: nil)
    dpop_token = generate_dpop_token(method, url)
    uri = URI(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    request = case method
    when "POST"
                Net::HTTP::Post.new(uri)
    when "GET"
                Net::HTTP::Get.new(uri)
    end

    request["Content-Type"] = "application/json"
    request["Authorization"] = "DPoP #{@access_token}"
    request["DPoP"] = dpop_token
    request.body = body.to_json if body

    response = http.request(request)

    # Always capture nonce from response
    @dpop_nonce = response["DPoP-Nonce"] if response["DPoP-Nonce"]

    response
  end

  def parse_response(response)
    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      { success: true, uri: result["uri"], cid: result["cid"] }
    else
      { success: false, error: response.body, status: response.code.to_i }
    end
  end

  def dpop_public_jwk
    point = @dpop_key.public_key
    point_bn = point.to_bn
    point_hex = point_bn.to_s(16)

    if point_hex.length == 130 && point_hex.start_with?("04")
      x_hex = point_hex[2, 64]
      y_hex = point_hex[66, 64]
    else
      x_hex = point_hex.rjust(64, "0")
      y_hex = point_hex.rjust(64, "0")
    end

    {
      kty: "EC",
      crv: "P-256",
      x: Base64.urlsafe_encode64([ x_hex ].pack("H*"), padding: false),
      y: Base64.urlsafe_encode64([ y_hex ].pack("H*"), padding: false)
    }
  end
end
