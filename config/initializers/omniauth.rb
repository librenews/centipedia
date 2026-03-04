require_relative "../../lib/omni_auth/atproto/key_manager"

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(:atproto,
    nil,
    nil,
    client_options: {
      site: "https://bsky.social",
      authorize_url: "https://bsky.social/oauth/authorize",
      token_url: "https://bsky.social/oauth/token"
    },
    scope: "atproto transition:generic",
    private_key: OmniAuth::Atproto::KeyManager.current_private_key,
    client_jwk: OmniAuth::Atproto::KeyManager.current_jwk,
    setup: proc { |env|
      request = Rack::Request.new(env)
      scheme = request.ssl? ? "https" : "http"

      app_url = if request.ssl? && request.port != 443
        "#{scheme}://#{request.host}"
      else
        "#{scheme}://#{request.host_with_port}"
      end

      client_id = "#{app_url}/oauth/client-metadata.json"
      env["omniauth.strategy"].options.client_id = client_id

      # Determine OAuth server from session PDS endpoint
      session = env["rack.session"]
      pds_endpoint = session&.[]("bluesky_pds_endpoint")

      use_main_oauth = pds_endpoint.blank? ||
        URI(pds_endpoint).host == "bsky.social" ||
        URI(pds_endpoint).host&.end_with?(".bsky.network")

      if use_main_oauth
        env["omniauth.strategy"].options.client_options[:site] = "https://bsky.social"
        env["omniauth.strategy"].options.client_options[:authorize_url] = "https://bsky.social/oauth/authorize"
        env["omniauth.strategy"].options.client_options[:token_url] = "https://bsky.social/oauth/token"
      else
        env["omniauth.strategy"].options.client_options[:site] = pds_endpoint
        env["omniauth.strategy"].options.client_options[:authorize_url] = "#{pds_endpoint}/oauth/authorize"
        env["omniauth.strategy"].options.client_options[:token_url] = "#{pds_endpoint}/oauth/token"
      end
    })
end

OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true
