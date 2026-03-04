require "test_helper"

class PdsClientTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @access_token = @user.access_token
    @client = PdsClient.new(user: @user, access_token: @access_token)
  end

  # --- extract_pds_endpoint ---

  test "extract_pds_endpoint reads aud from JWT" do
    # The alice fixture token has aud = "https://puffin.us-east.host.bsky.network"
    # But since it's a fake JWT, we test with a properly structured one
    payload = { aud: "https://my-pds.example.com", sub: "did:plc:alice123" }
    token = JWT.encode(payload, nil, "none")

    client = PdsClient.new(user: @user, access_token: token)
    assert_equal "https://my-pds.example.com", client.pds_endpoint
  end

  test "extract_pds_endpoint falls back to user pds_endpoint" do
    client = PdsClient.new(user: @user, access_token: nil)
    assert_equal "https://puffin.us-east.host.bsky.network", client.pds_endpoint
  end

  test "extract_pds_endpoint falls back to bsky.social when no info available" do
    user = User.new(did: "did:plc:nopds")
    client = PdsClient.new(user: user, access_token: nil)
    assert_equal "https://bsky.social", client.pds_endpoint
  end

  test "extract_pds_endpoint handles malformed JWT gracefully" do
    client = PdsClient.new(user: @user, access_token: "not.a.jwt")
    # Should fall back to user's pds_endpoint
    assert_includes [
      "https://puffin.us-east.host.bsky.network",
      "https://bsky.social"
    ], client.pds_endpoint
  end

  # --- generate_dpop_token ---

  test "generate_dpop_token produces a valid JWT" do
    token = @client.generate_dpop_token("POST", "https://example.com/xrpc/test")

    # Decode without verification (DPoP tokens use ephemeral keys)
    decoded = JWT.decode(token, nil, false)
    payload = decoded[0]
    header = decoded[1]

    assert_equal "POST", payload["htm"]
    assert_equal "https://example.com/xrpc/test", payload["htu"]
    assert payload["jti"].present?
    assert payload["iat"].is_a?(Integer)
    assert payload["exp"].is_a?(Integer)
    assert_equal "dpop+jwt", header["typ"]
    assert header["jwk"].present?
    assert_equal "EC", header["jwk"]["kty"]

    # Verify ath claim
    expected_hash = Base64.urlsafe_encode64(Digest::SHA256.digest(@access_token), padding: false)
    assert_equal expected_hash, payload["ath"]
  end

  test "generate_dpop_token includes nonce when set" do
    # Set a nonce by simulating a previous response
    @client.instance_variable_set(:@dpop_nonce, "test-nonce-123")

    token = @client.generate_dpop_token("GET", "https://example.com/xrpc/test")
    decoded = JWT.decode(token, nil, false)

    assert_equal "test-nonce-123", decoded[0]["nonce"]
  end

  test "generate_dpop_token omits nonce when not set" do
    token = @client.generate_dpop_token("GET", "https://example.com/xrpc/test")
    decoded = JWT.decode(token, nil, false)

    assert_nil decoded[0]["nonce"]
  end

  # --- create_post ---

  test "create_post returns error when no access token" do
    client = PdsClient.new(user: @user, access_token: nil)
    result = client.create_post("Hello world")

    assert_equal false, result[:success]
    assert_equal "No access token available", result[:error]
  end

  test "create_post returns error for blank text" do
    result = @client.create_post("")
    assert_equal false, result[:success]
    assert_equal "Post text cannot be blank", result[:error]
  end

  test "create_post returns error for whitespace-only text" do
    result = @client.create_post("   ")
    assert_equal false, result[:success]
    assert_equal "Post text cannot be blank", result[:error]
  end

  test "create_post succeeds on 200 response" do
    stub_create_record_success

    result = @client.create_post("Hello from Centipedia!")

    assert result[:success]
    assert_equal "at://did:plc:alice123/app.bsky.feed.post/abc", result[:uri]
    assert_equal "bafyreiabc", result[:cid]
  end

  test "create_post retries with nonce on 401" do
    # First request returns 401 with a nonce
    stub_request(:post, /com.atproto.repo.createRecord/)
      .to_return(
        { status: 401, body: '{"error":"use_dpop_nonce"}', headers: { "DPoP-Nonce" => "server-nonce-456" } },
        { status: 200, body: { uri: "at://did:plc:alice123/app.bsky.feed.post/retry", cid: "bafyretry" }.to_json }
      )

    result = @client.create_post("Test nonce retry")

    assert result[:success]
    assert_equal "at://did:plc:alice123/app.bsky.feed.post/retry", result[:uri]
    assert_equal "server-nonce-456", @client.dpop_nonce
  end

  test "create_post returns failure on persistent error" do
    stub_request(:post, /com.atproto.repo.createRecord/)
      .to_return(status: 403, body: '{"error":"Forbidden"}')

    result = @client.create_post("Forbidden post")

    assert_equal false, result[:success]
    assert_equal 403, result[:status]
  end

  test "create_post captures nonce from successful response" do
    stub_request(:post, /com.atproto.repo.createRecord/)
      .to_return(
        status: 200,
        body: { uri: "at://test/post/1", cid: "bafytest" }.to_json,
        headers: { "DPoP-Nonce" => "new-nonce" }
      )

    @client.create_post("Test nonce capture")
    assert_equal "new-nonce", @client.dpop_nonce
  end

  test "create_post handles network exceptions" do
    stub_request(:post, /com.atproto.repo.createRecord/).to_raise(Errno::ECONNREFUSED)

    result = @client.create_post("Network error")

    assert_equal false, result[:success]
    assert result[:error].present?
  end

  private

  def stub_create_record_success
    stub_request(:post, /com.atproto.repo.createRecord/)
      .to_return(
        status: 200,
        body: { uri: "at://did:plc:alice123/app.bsky.feed.post/abc", cid: "bafyreiabc" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
