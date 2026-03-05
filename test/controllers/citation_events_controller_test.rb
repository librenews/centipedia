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

  test "should create citation via full pipeline" do
    url = "https://controller-test.example.com/article"
    html = "<html><head><title>Test</title></head><body><article>Content.</article></body></html>"

    stub_request(:get, url).to_return(status: 200, body: html, headers: { "Content-Type" => "text/html" })

    assert_difference("CitationEvent.count", 1) do
      post topic_citation_events_url(@topic), params: { canonical_url: url }
    end

    assert_redirected_to topic_url(@topic)
    assert_match(/scored/, flash[:notice])
  end

  test "should handle submission error" do
    post topic_citation_events_url(@topic), params: { canonical_url: "not-a-url" }
    assert_redirected_to new_topic_citation_event_url(@topic)
    assert_match(/failed/, flash[:alert])
  end
end
