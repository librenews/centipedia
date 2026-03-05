require "test_helper"

class AiSynthesisServiceTest < ActiveSupport::TestCase
  setup do
    @topic = topics(:one)
    @user = users(:alice)
    @domain = domains(:one)
    @source = sources(:one)

    # Ensure the source has article content for the prompt
    @source.update!(
      article_title: "Test Article",
      article_content: "This is the full text of a test article with important claims.",
      content_hash: Digest::SHA256.hexdigest("test content"),
      status: "live"
    )

    @citation = CitationEvent.create!(
      topic: @topic,
      source: @source,
      user: @user,
      event_type: "submitted",
      url_base_score: 7.0,
      domain_multiplier: 1.2,
      corroboration_multiplier: 1.0,
      total_weight: 8.4,
      rubric_version: "1.0.0"
    )
  end

  test "raises error when no scored citations exist" do
    empty_topic = Topic.create!(title: "Empty Topic", slug: "empty-topic")

    service = AiSynthesisService.new(empty_topic)

    error = assert_raises(AiSynthesisService::SynthesisError) do
      service.synthesize!
    end

    assert_includes error.message, "No scored citations"
  end

  test "parses valid LLM JSON response into an article" do
    valid_json = [
      {
        "section" => "Summary",
        "claims" => [
          {
            "text" => "This is a key finding from the test article.",
            "citation_event_ids" => [ @citation.id ]
          }
        ]
      }
    ].to_json

    mock_openai_response(valid_json)

    service = AiSynthesisService.new(@topic)
    article = service.synthesize!

    assert_equal "published", article.status
    assert_equal "1.0.0", article.rubric_version
    assert_equal 1, article.content.length
    assert_equal "Summary", article.content.first["section"]
    assert_equal 1, article.content.first["claims"].length
  end

  test "handles LLM response wrapped in markdown fences" do
    valid_json = [
      {
        "section" => "Overview",
        "claims" => [
          { "text" => "A fact.", "citation_event_ids" => [ @citation.id ] }
        ]
      }
    ].to_json

    fenced_response = "```json\n#{valid_json}\n```"

    mock_openai_response(fenced_response)

    service = AiSynthesisService.new(@topic)
    article = service.synthesize!

    assert_equal "published", article.status
    assert_equal 1, article.content.length
  end

  test "raises error on malformed JSON from LLM" do
    mock_openai_response("this is not valid json at all")

    service = AiSynthesisService.new(@topic)

    error = assert_raises(AiSynthesisService::SynthesisError) do
      service.synthesize!
    end

    assert_includes error.message, "Failed to parse LLM response"
  end

  test "raises error on invalid section structure" do
    bad_structure = [ { "wrong_key" => "no section field" } ].to_json

    mock_openai_response(bad_structure)

    service = AiSynthesisService.new(@topic)

    error = assert_raises(AiSynthesisService::SynthesisError) do
      service.synthesize!
    end

    assert_includes error.message, "Invalid section structure"
  end

  test "marks previous articles as outdated when new one is published" do
    # Create an existing published article
    old_article = @topic.articles.create!(
      content: [ { "section" => "Old", "claims" => [] } ],
      rubric_version: "1.0.0",
      status: "published"
    )

    valid_json = [
      {
        "section" => "New Summary",
        "claims" => [
          { "text" => "Updated fact.", "citation_event_ids" => [ @citation.id ] }
        ]
      }
    ].to_json

    mock_openai_response(valid_json)

    service = AiSynthesisService.new(@topic)
    new_article = service.synthesize!

    assert_equal "published", new_article.status
    assert_equal "outdated", old_article.reload.status
  end

  private

  def mock_openai_response(content)
    stub_request(:post, "https://api.openai.com/v1/chat/completions")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          "choices" => [
            {
              "message" => {
                "role" => "assistant",
                "content" => content
              }
            }
          ]
        }.to_json
      )
  end
end
