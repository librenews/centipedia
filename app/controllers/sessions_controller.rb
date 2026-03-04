class SessionsController < ApplicationController
  # POST /auth/bluesky/start
  # Resolves the handle, stores DID/PDS in session, then redirects to OmniAuth.
  def start
    handle = params[:handle].to_s.strip

    if handle.blank?
      redirect_to root_path, alert: "Please enter your Bluesky handle."
      return
    end

    handle = handle.gsub(/^@/, "")

    result = BlueskyIdentityService.resolve_handle(handle)

    if result[:error]
      redirect_to root_path, alert: "Failed to resolve handle: #{result[:error]}"
      return
    end

    session[:bluesky_handle] = handle
    session[:bluesky_did] = result[:did]
    session[:bluesky_pds_endpoint] = result[:pds_endpoint]

    redirect_to "/auth/atproto", allow_other_host: false
  end

  # GET /auth/atproto/callback
  # Processes the OmniAuth response, creates/updates the user, and logs them in.
  def callback
    auth_hash = request.env["omniauth.auth"]

    unless auth_hash
      redirect_to root_path, alert: "Authentication failed."
      return
    end

    did = auth_hash.dig("info", "did")
    unless did
      redirect_to root_path, alert: "Could not retrieve account information."
      return
    end

    credentials = auth_hash["credentials"] || {}
    handle = auth_hash.dig("info", "handle") || session[:bluesky_handle]
    pds_endpoint = session[:bluesky_pds_endpoint]

    # Initialize user with minimal info first
    user = User.find_or_initialize_by(did: did)
    user.handle = handle
    user.pds_endpoint = pds_endpoint
    user.access_token = credentials["token"]
    user.refresh_token = credentials["refresh_token"]
    user.token_expires_at = credentials["expires_at"] ? Time.at(credentials["expires_at"].to_i) : nil

    # Fetch fresh profile from PDS
    pds_client = PdsClient.new(user: user, access_token: user.access_token)
    profile_result = pds_client.get_profile

    display_name = auth_hash.dig("info", "name") || handle
    avatar_url = auth_hash.dig("info", "image")

    if profile_result[:success] && profile_result[:profile]
      profile = profile_result[:profile]
      display_name = profile["displayName"] if profile["displayName"].present?

      if profile["avatar"].present?
        # Bluesky avatars are stored as blobs. The format is a legacy CID structure.
        avatar_ref = profile["avatar"].is_a?(Hash) ? profile["avatar"]["ref"] : profile["avatar"]
        if avatar_ref.is_a?(Hash) && avatar_ref["$link"]
          # Handle the `{ "$link": "bafkrei..." }` format
          avatar_cid = avatar_ref["$link"]
          avatar_url = "https://cdn.bsky.app/img/avatar/plain/#{did}/#{avatar_cid}@jpeg"
        elsif avatar_ref.is_a?(String)
          avatar_url = "https://cdn.bsky.app/img/avatar/plain/#{did}/#{avatar_ref}@jpeg"
        end
      end
    end

    user.display_name = display_name
    user.avatar_url = avatar_url
    user.save!

    session[:user_id] = user.id
    session[:oauth_access_token] = credentials["token"]

    redirect_to root_path, notice: "Connected as @#{handle}!"
  end

  # DELETE /logout
  def destroy
    reset_session
    redirect_to root_path, notice: "Logged out."
  end

  # GET /auth/failure
  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end

  # GET /oauth/client-metadata.json
  # Serves the OAuth client metadata required by AT Protocol OAuth.
  def client_metadata
    require_relative "../../lib/omni_auth/atproto/key_manager"

    app_url = build_app_url

    metadata = {
      client_id: "#{app_url}/oauth/client-metadata.json",
      application_type: "web",
      client_name: "Centipedia",
      client_uri: app_url,
      dpop_bound_access_tokens: true,
      grant_types: [ "authorization_code", "refresh_token" ],
      redirect_uris: [ "#{app_url}/auth/atproto/callback" ],
      response_types: [ "code" ],
      scope: "atproto transition:generic",
      token_endpoint_auth_method: "private_key_jwt",
      token_endpoint_auth_signing_alg: "ES256",
      jwks: {
        keys: [ OmniAuth::Atproto::KeyManager.current_jwk ]
      }
    }

    render json: metadata
  rescue => e
    Rails.logger.error "Error generating client metadata: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def build_app_url
    rack_request = Rack::Request.new(request.env)
    scheme = rack_request.ssl? ? "https" : "http"

    if rack_request.ssl? && rack_request.port != 443
      "#{scheme}://#{rack_request.host}"
    else
      "#{scheme}://#{rack_request.host_with_port}"
    end
  end
end
