class BlueskyIdentityService
  require "net/http"
  require "json"

  # Resolve a Bluesky handle to DID and PDS endpoint.
  #
  # @param handle [String] e.g. "user.bsky.social" or "@user.example.com"
  # @return [Hash] { did:, pds_endpoint:, handle: } or { error: }
  def self.resolve_handle(handle)
    clean_handle = handle.to_s.gsub(/^@/, "").strip
    return { error: "Handle cannot be blank" } if clean_handle.blank?

    did = fetch_did_for_handle(clean_handle)
    return did if did[:error]

    pds_endpoint = resolve_did_to_pds(did[:did])

    {
      did: did[:did],
      pds_endpoint: pds_endpoint,
      handle: clean_handle
    }
  rescue => e
    Rails.logger.error "Error resolving handle #{handle}: #{e.message}"
    { error: "Resolution failed: #{e.message}" }
  end

  # Fetch DID from handle using AT Protocol identity resolver.
  #
  # @param handle [String] cleaned handle string
  # @return [Hash] { did: } or { error: }
  def self.fetch_did_for_handle(handle)
    uri = URI("https://bsky.social/xrpc/com.atproto.identity.resolveHandle")
    uri.query = URI.encode_www_form({ handle: handle })

    response = make_get_request(uri)

    unless response.code == "200"
      return { error: "Failed to resolve handle: HTTP #{response.code}" }
    end

    data = JSON.parse(response.body)
    did = data["did"]

    if did.present?
      { did: did }
    else
      { error: "No DID found for handle" }
    end
  end

  # Resolve a DID to its PDS endpoint.
  #
  # @param did [String] e.g. "did:plc:abc123"
  # @return [String] PDS endpoint URL
  def self.resolve_did_to_pds(did)
    parts = did.to_s.split(":")
    return "https://bsky.social" unless parts.length >= 3

    case parts[1]
    when "plc"
      resolve_plc_did(did)
    when "web"
      resolve_web_did(did)
    else
      "https://bsky.social"
    end
  end

  # Resolve a PLC DID via plc.directory.
  def self.resolve_plc_did(did)
    uri = URI("https://plc.directory/#{did}")
    response = make_get_request(uri, timeout: 5)

    if response.code == "200"
      data = JSON.parse(response.body)
      extract_pds_from_did_document(data) || "https://bsky.social"
    else
      "https://bsky.social"
    end
  rescue => e
    Rails.logger.warn "Failed to resolve PLC DID: #{e.message}" if defined?(Rails)
    "https://bsky.social"
  end

  # Resolve a Web DID via .well-known/did.json.
  def self.resolve_web_did(did)
    parts = did.split(":")
    return "https://bsky.social" if parts.length < 3

    domain = parts[2]
    uri = URI("https://#{domain}/.well-known/did.json")
    response = make_get_request(uri, timeout: 5)

    if response.code == "200"
      data = JSON.parse(response.body)
      extract_pds_from_did_document(data) || "https://bsky.social"
    else
      "https://bsky.social"
    end
  rescue => e
    Rails.logger.warn "Failed to resolve Web DID: #{e.message}" if defined?(Rails)
    "https://bsky.social"
  end

  # Extract PDS endpoint from a DID document's service array.
  def self.extract_pds_from_did_document(doc)
    return nil unless doc["service"].is_a?(Array)

    pds_service = doc["service"].find { |s| s["type"] == "AtprotoPersonalDataServer" }
    pds_service&.dig("serviceEndpoint")
  end

  private_class_method def self.make_get_request(uri, timeout: 10)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.read_timeout = timeout
    http.open_timeout = timeout

    request = Net::HTTP::Get.new(uri)
    request["Accept"] = "application/json"
    http.request(request)
  end
end
