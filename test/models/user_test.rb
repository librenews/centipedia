require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with all fields" do
    user = users(:alice)
    assert user.valid?
  end

  test "requires did" do
    user = User.new(handle: "test.bsky.social")
    assert_not user.valid?
    assert_includes user.errors[:did], "can't be blank"
  end

  test "enforces did uniqueness" do
    User.create!(did: "did:plc:unique123", handle: "first.bsky.social")
    duplicate = User.new(did: "did:plc:unique123", handle: "second.bsky.social")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:did], "has already been taken"
  end

  test "valid with only did" do
    user = User.new(did: "did:plc:minimal")
    assert user.valid?
  end

  # --- token_expired? ---

  test "token_expired? returns true when token_expires_at is nil" do
    user = users(:bob)
    assert user.token_expired?
  end

  test "token_expired? returns true when token has expired" do
    user = users(:expired_user)
    assert user.token_expired?
  end

  test "token_expired? returns false when token is still valid" do
    user = users(:alice)
    assert_not user.token_expired?
  end

  # --- avatar_display_url ---

  test "avatar_display_url returns avatar_url when present" do
    user = users(:alice)
    assert_equal "https://cdn.bsky.app/img/avatar/alice.jpg", user.avatar_display_url
  end

  test "avatar_display_url returns placeholder when avatar_url is nil" do
    user = users(:bob)
    url = user.avatar_display_url
    assert_includes url, "ui-avatars.com"
    assert_includes url, "Bob"
  end

  test "avatar_display_url uses handle when display_name is also nil" do
    user = User.new(did: "did:plc:noname", handle: "noname.bsky.social")
    url = user.avatar_display_url
    assert_includes url, "noname.bsky.social"
  end

  test "avatar_display_url falls back to User when everything is nil" do
    user = User.new(did: "did:plc:empty")
    url = user.avatar_display_url
    assert_includes url, "User"
  end
end
