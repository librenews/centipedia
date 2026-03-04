require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  # --- start ---

  test "start redirects with alert when handle is blank" do
    post start_bluesky_auth_path, params: { handle: "" }
    assert_redirected_to root_path
    assert_equal "Please enter your Bluesky handle.", flash[:alert]
  end

  test "start redirects with alert when handle param is missing" do
    post start_bluesky_auth_path
    assert_redirected_to root_path
    assert_equal "Please enter your Bluesky handle.", flash[:alert]
  end

  test "start resolves handle and redirects to omniauth" do
    stub_request(:get, /com.atproto.identity.resolveHandle/)
      .to_return(status: 200, body: { did: "did:plc:test123" }.to_json)
    stub_request(:get, /plc.directory/)
      .to_return(status: 200, body: {
        service: [ { type: "AtprotoPersonalDataServer", serviceEndpoint: "https://bsky.social" } ]
      }.to_json)

    post start_bluesky_auth_path, params: { handle: "test.bsky.social" }
    assert_redirected_to "/auth/atproto"
  end

  test "start strips @ from handle" do
    stub_request(:get, "https://bsky.social/xrpc/com.atproto.identity.resolveHandle?handle=test.bsky.social")
      .to_return(status: 200, body: { did: "did:plc:test123" }.to_json)
    stub_request(:get, /plc.directory/)
      .to_return(status: 200, body: {
        service: [ { type: "AtprotoPersonalDataServer", serviceEndpoint: "https://bsky.social" } ]
      }.to_json)

    post start_bluesky_auth_path, params: { handle: "@test.bsky.social" }
    assert_redirected_to "/auth/atproto"
  end

  test "start redirects with alert on resolution failure" do
    stub_request(:get, /com.atproto.identity.resolveHandle/)
      .to_return(status: 404, body: '{"error":"NotFound"}')

    post start_bluesky_auth_path, params: { handle: "nonexistent.bsky.social" }
    assert_redirected_to root_path
    assert_match(/Failed to resolve handle/, flash[:alert])
  end

  # --- callback ---

  test "callback creates new user and logs in" do
    OmniAuth.config.mock_auth[:atproto] = OmniAuth::AuthHash.new({
      "info" => {
        "did" => "did:plc:newuser",
        "handle" => "newuser.bsky.social",
        "name" => "New User",
        "image" => "https://cdn.bsky.app/avatar/new.jpg"
      },
      "credentials" => {
        "token" => "new_access_token",
        "refresh_token" => "new_refresh_token",
        "expires_at" => 1.hour.from_now.to_i
      }
    })

    stub_request(:get, /com.atproto.repo.getRecord/)
      .to_return(status: 200, body: '{"value":{"avatar":{"ref":{"$link":"bafyavatar"}}}}')

    assert_difference "User.count", 1 do
      get "/auth/atproto/callback"
    end

    assert_redirected_to root_path
    follow_redirect!
    assert_match(/Connected as @newuser.bsky.social/, flash[:notice] || response.body)

    user = User.find_by(did: "did:plc:newuser")
    assert_equal "newuser.bsky.social", user.handle
    assert_equal "New User", user.display_name
    assert_equal "https://cdn.bsky.app/img/avatar/plain/did:plc:newuser/bafyavatar@jpeg", user.avatar_url
    assert_equal "new_access_token", user.access_token
  end

  test "callback updates existing user" do
    alice = users(:alice)

    OmniAuth.config.mock_auth[:atproto] = OmniAuth::AuthHash.new({
      "info" => {
        "did" => alice.did,
        "handle" => "alice-updated.bsky.social",
        "name" => "Alice Updated",
        "image" => "https://cdn.bsky.app/avatar/alice-new.jpg"
      },
      "credentials" => {
        "token" => "updated_token",
        "refresh_token" => "updated_refresh",
        "expires_at" => 1.hour.from_now.to_i
      }
    })

    stub_request(:get, /com.atproto.repo.getRecord/)
      .to_return(status: 200, body: '{"value":{"displayName":"Alice Profile Name"}}')

    assert_no_difference "User.count" do
      get "/auth/atproto/callback"
    end

    alice.reload
    assert_equal "alice-updated.bsky.social", alice.handle
    assert_equal "Alice Profile Name", alice.display_name
    assert_equal "updated_token", alice.access_token
  end

  test "callback redirects with alert when auth fails" do
    OmniAuth.config.mock_auth[:atproto] = :invalid_credentials

    get "/auth/atproto/callback"
    # OmniAuth test mode redirects to failure path
    assert_redirected_to "/auth/failure?message=invalid_credentials&strategy=atproto"
  end

  # --- destroy ---

  test "destroy clears session and redirects" do
    log_in_as(users(:alice))

    delete logout_path
    assert_redirected_to root_path
    assert_equal "Logged out.", flash[:notice]
  end

  # --- failure ---

  test "failure redirects with error message" do
    get "/auth/failure", params: { message: "invalid_credentials" }
    assert_redirected_to root_path
    assert_match(/invalid_credentials/, flash[:alert])
  end

  # --- client_metadata ---

  test "client_metadata returns valid JSON" do
    get client_metadata_path

    assert_response :success
    metadata = JSON.parse(response.body)

    assert_match %r{/oauth/client-metadata\.json$}, metadata["client_id"]
    assert_equal "web", metadata["application_type"]
    assert_equal "Centipedia", metadata["client_name"]
    assert_equal true, metadata["dpop_bound_access_tokens"]
    assert_includes metadata["grant_types"], "authorization_code"
    assert_includes metadata["grant_types"], "refresh_token"
    assert_includes metadata["response_types"], "code"
    assert_equal "atproto transition:generic", metadata["scope"]
    assert_equal "private_key_jwt", metadata["token_endpoint_auth_method"]
    assert_equal "ES256", metadata["token_endpoint_auth_signing_alg"]

    assert metadata["jwks"].present?
    assert metadata["jwks"]["keys"].is_a?(Array)
    assert_equal "EC", metadata["jwks"]["keys"].first["kty"]
  end

  test "client_metadata redirect_uris point to callback" do
    get client_metadata_path

    metadata = JSON.parse(response.body)
    assert metadata["redirect_uris"].first.end_with?("/auth/atproto/callback")
  end
end
