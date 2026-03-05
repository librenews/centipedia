require "test_helper"

class CitationEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @topic = topics(:one)
    @user = users(:alice)

    # Mock login
    log_in_as(@user)
  end

  test "should get new" do
    get new_topic_citation_event_url(@topic)
    assert_response :success
  end

  test "should get create" do
    post topic_citation_events_url(@topic)
    assert_redirected_to topic_url(@topic)
  end
end
