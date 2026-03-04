require "test_helper"

class BlueskyIdentityServiceTest < ActiveSupport::TestCase
  # --- resolve_handle ---

  test "resolve_handle returns did and pds_endpoint for valid handle" do
    stub_handle_resolution("alice.bsky.social", "did:plc:alice123")
    stub_plc_directory("did:plc:alice123", "https://puffin.us-east.host.bsky.network")

    result = BlueskyIdentityService.resolve_handle("alice.bsky.social")

    assert_equal "did:plc:alice123", result[:did]
    assert_equal "https://puffin.us-east.host.bsky.network", result[:pds_endpoint]
    assert_equal "alice.bsky.social", result[:handle]
    assert_nil result[:error]
  end

  test "resolve_handle strips @ prefix" do
    stub_handle_resolution("alice.bsky.social", "did:plc:alice123")
    stub_plc_directory("did:plc:alice123", "https://bsky.social")

    result = BlueskyIdentityService.resolve_handle("@alice.bsky.social")

    assert_equal "alice.bsky.social", result[:handle]
    assert_equal "did:plc:alice123", result[:did]
  end

  test "resolve_handle returns error for blank handle" do
    result = BlueskyIdentityService.resolve_handle("")
    assert_equal "Handle cannot be blank", result[:error]
  end

  test "resolve_handle returns error for nil handle" do
    result = BlueskyIdentityService.resolve_handle(nil)
    assert_equal "Handle cannot be blank", result[:error]
  end

  test "resolve_handle returns error when API returns non-200" do
    stub_request(:get, /com.atproto.identity.resolveHandle/)
      .to_return(status: 404, body: '{"error":"NotFound"}')

    result = BlueskyIdentityService.resolve_handle("nonexistent.bsky.social")
    assert_match(/Failed to resolve handle/, result[:error])
  end

  test "resolve_handle returns error when no DID in response" do
    stub_request(:get, /com.atproto.identity.resolveHandle/)
      .to_return(status: 200, body: "{}")

    result = BlueskyIdentityService.resolve_handle("broken.bsky.social")
    assert_equal "No DID found for handle", result[:error]
  end

  # --- fetch_did_for_handle ---

  test "fetch_did_for_handle returns did on success" do
    stub_handle_resolution("test.bsky.social", "did:plc:test999")

    result = BlueskyIdentityService.fetch_did_for_handle("test.bsky.social")
    assert_equal "did:plc:test999", result[:did]
  end

  test "fetch_did_for_handle returns error on HTTP failure" do
    stub_request(:get, /com.atproto.identity.resolveHandle/)
      .to_return(status: 500, body: "Server Error")

    result = BlueskyIdentityService.fetch_did_for_handle("fail.bsky.social")
    assert_match(/Failed to resolve handle/, result[:error])
  end

  # --- resolve_did_to_pds ---

  test "resolve_did_to_pds resolves PLC DID" do
    stub_plc_directory("did:plc:abc", "https://my-pds.example.com")

    result = BlueskyIdentityService.resolve_did_to_pds("did:plc:abc")
    assert_equal "https://my-pds.example.com", result
  end

  test "resolve_did_to_pds resolves Web DID" do
    stub_request(:get, "https://example.com/.well-known/did.json")
      .to_return(status: 200, body: {
        service: [ { type: "AtprotoPersonalDataServer", serviceEndpoint: "https://pds.example.com" } ]
      }.to_json)

    result = BlueskyIdentityService.resolve_did_to_pds("did:web:example.com")
    assert_equal "https://pds.example.com", result
  end

  test "resolve_did_to_pds falls back to bsky.social for unknown method" do
    result = BlueskyIdentityService.resolve_did_to_pds("did:key:z6Mk123")
    assert_equal "https://bsky.social", result
  end

  test "resolve_did_to_pds falls back for malformed DID" do
    result = BlueskyIdentityService.resolve_did_to_pds("not-a-did")
    assert_equal "https://bsky.social", result
  end

  # --- extract_pds_from_did_document ---

  test "extract_pds_from_did_document finds PDS in service array" do
    doc = {
      "service" => [
        { "type" => "AtprotoPersonalDataServer", "serviceEndpoint" => "https://my-pds.net" }
      ]
    }
    assert_equal "https://my-pds.net", BlueskyIdentityService.extract_pds_from_did_document(doc)
  end

  test "extract_pds_from_did_document returns nil when no service array" do
    assert_nil BlueskyIdentityService.extract_pds_from_did_document({})
  end

  test "extract_pds_from_did_document returns nil when service is not array" do
    assert_nil BlueskyIdentityService.extract_pds_from_did_document({ "service" => "not-an-array" })
  end

  test "extract_pds_from_did_document returns nil when no PDS type" do
    doc = {
      "service" => [
        { "type" => "SomethingElse", "serviceEndpoint" => "https://other.net" }
      ]
    }
    assert_nil BlueskyIdentityService.extract_pds_from_did_document(doc)
  end

  # --- resolve_plc_did ---

  test "resolve_plc_did falls back on network error" do
    stub_request(:get, /plc.directory/).to_timeout

    result = BlueskyIdentityService.resolve_plc_did("did:plc:timeout")
    assert_equal "https://bsky.social", result
  end

  # --- resolve_web_did ---

  test "resolve_web_did falls back for short DID" do
    result = BlueskyIdentityService.resolve_web_did("did:web")
    assert_equal "https://bsky.social", result
  end

  test "resolve_web_did falls back on network error" do
    stub_request(:get, /\.well-known\/did\.json/).to_timeout

    result = BlueskyIdentityService.resolve_web_did("did:web:timeout.com")
    assert_equal "https://bsky.social", result
  end

  private

  def stub_handle_resolution(handle, did)
    stub_request(:get, "https://bsky.social/xrpc/com.atproto.identity.resolveHandle?handle=#{handle}")
      .to_return(status: 200, body: { did: did }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_plc_directory(did, pds_endpoint)
    stub_request(:get, "https://plc.directory/#{did}")
      .to_return(status: 200, body: {
        service: [ { type: "AtprotoPersonalDataServer", serviceEndpoint: pds_endpoint } ]
      }.to_json, headers: { "Content-Type" => "application/json" })
  end
end
