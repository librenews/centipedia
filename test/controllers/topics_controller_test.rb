require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @topic = topics(:one)
  end

  test "should get index" do
    get topics_url
    assert_response :success
  end

  test "should get show" do
    get topic_url(@topic)
    assert_response :success
  end
end
