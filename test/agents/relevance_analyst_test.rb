require "test_helper"

class RelevanceAnalystTest < ActiveSupport::TestCase
  setup do
    @topic = topics(:one)
    @citation = citation_events(:one)
    # Mock source content that mentions the topic title
    @citation.source.update!(article_content: "#{@topic.title} is discussed extensively here. #{@topic.title} has many implications.")
  end

  test "scores relevance based on topic keyword mentions" do
    agent = Agents::RelevanceAnalyst.new
    context = { topic: @topic, citations: [ @citation ] }

    result = agent.run(context)

    assert result[:relevance_scores].present?
    score = result[:relevance_scores].first
    assert_equal @citation.id, score[:citation_event_id]
    assert score[:relevance_score] > 0.0
    assert score[:depth_of_coverage].is_a?(Numeric)
  end

  test "returns low relevance for unrelated content" do
    @citation.source.update!(article_content: "This article is completely unrelated.")

    agent = Agents::RelevanceAnalyst.new
    context = { topic: @topic, citations: [ @citation ] }

    result = agent.run(context)

    score = result[:relevance_scores].first
    assert_equal 0.0, score[:relevance_score]
  end
end
