require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  # --- index (logged out) ---

  test "index shows landing page when logged out" do
    get root_path

    assert_response :success
    assert_select "h1", "Centipedia"
    assert_select ".hero-subtitle"
    assert_select "#login-section"
    assert_select "#handle"
    assert_select "#submit-login"
  end

  test "index shows core principles when logged out" do
    get root_path

    assert_response :success
    assert_select ".principles ol li", minimum: 5
  end

  test "index does not show profile card when logged out" do
    get root_path

    assert_select "#profile-card", false
    assert_select "#test-post-section", false
  end

  # --- index (logged in) ---

  test "index shows dashboard when logged in" do
    log_in_as(users(:alice))
    get root_path

    assert_response :success
    assert_select "h1", "Dashboard"
    assert_select "#profile-card"
    assert_select "#profile-avatar"
    assert_select "#test-post-section"
  end

  test "index shows user profile info when logged in" do
    log_in_as(users(:alice))
    get root_path

    assert_response :success
    assert_select ".profile-info" do
      assert_select ".profile-did", /did:plc:alice123/
    end
  end

  test "index does not show login form when logged in" do
    log_in_as(users(:alice))
    get root_path

    assert_select "#login-section", false
    assert_select ".hero", false
  end

  # --- test_post ---

  test "test_post requires authentication" do
    post test_post_path, params: { post_text: "Hello" }
    assert_redirected_to root_path
    assert_equal "You must be logged in to do that.", flash[:alert]
  end

  test "test_post redirects with alert when text is blank" do
    log_in_as(users(:alice))
    post test_post_path, params: { post_text: "" }
    assert_redirected_to root_path
    assert_equal "Post text cannot be blank.", flash[:alert]
  end

  test "test_post succeeds and redirects with notice" do
    log_in_as(users(:alice))

    stub_request(:post, /com.atproto.repo.createRecord/)
      .to_return(
        status: 200,
        body: { uri: "at://did:plc:alice123/app.bsky.feed.post/test", cid: "bafytest" }.to_json
      )

    post test_post_path, params: { post_text: "Hello from Centipedia!" }
    assert_redirected_to root_path
    assert_match(/Post created successfully/, flash[:notice])
  end

  test "test_post redirects with alert on PDS error" do
    log_in_as(users(:alice))

    stub_request(:post, /com.atproto.repo.createRecord/)
      .to_return(status: 500, body: '{"error":"InternalServerError"}')

    post test_post_path, params: { post_text: "This will fail" }
    assert_redirected_to root_path
    assert_match(/Failed to create post/, flash[:alert])
  end
end
