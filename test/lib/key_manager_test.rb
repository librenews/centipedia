require "test_helper"
require "omni_auth/atproto/key_manager"

class KeyManagerTest < ActiveSupport::TestCase
  setup do
    @test_dir = Dir.mktmpdir("centipedia_keys_test")
    @original_private_key_path = OmniAuth::Atproto::KeyManager.private_key_path
    @original_jwk_path = OmniAuth::Atproto::KeyManager.jwk_path

    # Point key paths to temp directory
    OmniAuth::Atproto::KeyManager.define_singleton_method(:private_key_path) do
      File.join(@test_dir, "atproto_private_key.pem")
    end.tap { |_| @test_dir_ref = @test_dir }

    test_dir = @test_dir
    OmniAuth::Atproto::KeyManager.define_singleton_method(:private_key_path) { File.join(test_dir, "atproto_private_key.pem") }
    OmniAuth::Atproto::KeyManager.define_singleton_method(:jwk_path) { File.join(test_dir, "atproto_jwk.json") }
  end

  teardown do
    FileUtils.rm_rf(@test_dir)

    # Capture in local variables so the block closure can access them
    original_private_key_path = @original_private_key_path
    original_jwk_path = @original_jwk_path

    # Restore original paths
    OmniAuth::Atproto::KeyManager.define_singleton_method(:private_key_path) { original_private_key_path }
    OmniAuth::Atproto::KeyManager.define_singleton_method(:jwk_path) { original_jwk_path }
  end

  test "generate_keys creates private key file" do
    OmniAuth::Atproto::KeyManager.generate_keys
    assert File.exist?(OmniAuth::Atproto::KeyManager.private_key_path)
  end

  test "generate_keys creates JWK file" do
    OmniAuth::Atproto::KeyManager.generate_keys
    assert File.exist?(OmniAuth::Atproto::KeyManager.jwk_path)
  end

  test "generated private key is a valid EC P-256 key" do
    OmniAuth::Atproto::KeyManager.generate_keys
    key = OpenSSL::PKey::EC.new(File.read(OmniAuth::Atproto::KeyManager.private_key_path))
    assert key.private_key?
    assert_equal "prime256v1", key.group.curve_name
  end

  test "generated JWK has correct structure" do
    OmniAuth::Atproto::KeyManager.generate_keys
    jwk = JSON.parse(File.read(OmniAuth::Atproto::KeyManager.jwk_path))

    assert_equal "EC", jwk["kty"]
    assert_equal "P-256", jwk["crv"]
    assert_equal "sig", jwk["use"]
    assert_equal "ES256", jwk["alg"]
    assert jwk["x"].present?
    assert jwk["y"].present?
    assert jwk["kid"].present?
  end

  test "current_private_key auto-generates keys if missing" do
    assert_not OmniAuth::Atproto::KeyManager.keys_exist?

    key = OmniAuth::Atproto::KeyManager.current_private_key
    assert key.is_a?(OpenSSL::PKey::EC)
    assert OmniAuth::Atproto::KeyManager.keys_exist?
  end

  test "current_jwk auto-generates keys if missing" do
    assert_not OmniAuth::Atproto::KeyManager.keys_exist?

    jwk = OmniAuth::Atproto::KeyManager.current_jwk
    assert jwk.is_a?(Hash)
    assert_equal "EC", jwk["kty"]
    assert OmniAuth::Atproto::KeyManager.keys_exist?
  end

  test "current_private_key returns same key on repeated calls" do
    key1 = OmniAuth::Atproto::KeyManager.current_private_key
    key2 = OmniAuth::Atproto::KeyManager.current_private_key
    assert_equal key1.to_pem, key2.to_pem
  end

  test "current_jwk returns same JWK on repeated calls" do
    jwk1 = OmniAuth::Atproto::KeyManager.current_jwk
    jwk2 = OmniAuth::Atproto::KeyManager.current_jwk
    assert_equal jwk1, jwk2
  end

  test "keys_exist? returns false when no keys" do
    assert_not OmniAuth::Atproto::KeyManager.keys_exist?
  end

  test "keys_exist? returns true after generation" do
    OmniAuth::Atproto::KeyManager.generate_keys
    assert OmniAuth::Atproto::KeyManager.keys_exist?
  end
end
