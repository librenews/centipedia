require "test_helper"

class AgentPipelineTest < ActiveSupport::TestCase
  setup do
    @topic = topics(:one)
    @user = users(:alice)
    @domain = domains(:one)

    @source = Source.create!(
      canonical_url: "https://pipeline-test.example.com/article",
      domain: @domain,
      status: "live",
      article_content: "#{@topic.title} is an important subject with significant implications."
    )

    @citation = CitationEvent.create!(
      source: @source,
      topic: @topic,
      user: @user,
      event_type: "submitted",
      url_base_score: 5.0,
      domain_multiplier: 1.0,
      corroboration_multiplier: 1.0,
      total_weight: 5.0,
      rubric_version: "1.0.0"
    )
  end

  test "raises error with empty citations" do
    pipeline = AgentPipeline.new(topic: @topic, citations: [])

    error = assert_raises(AgentPipeline::PipelineError) do
      pipeline.run!
    end

    assert_includes error.message, "No citations"
  end

  test "runs the evaluation agents and updates citation scores" do
    # Create a mock pipeline that skips the LLM call (replaces SynthesisWriter)
    mock_writer = Class.new(BaseAgent) do
      def name = "Mock Writer"
      def description = "Test writer"
      def run(context)
        context.merge(article_content: [
          {
            "section" => "Test Section",
            "claims" => [
              { "text" => "Test claim.", "citation_event_ids" => [ context[:citations].first.id ] }
            ]
          }
        ])
      end
    end

    # Monkey-patch the pipeline to use our mock writer
    pipeline = AgentPipeline.new(topic: @topic, citations: [ @citation ])
    pipeline.define_singleton_method(:agents) do
      [
        Agents::RelevanceAnalyst.new,
        Agents::AuthorityEvaluator.new,
        Agents::EvidenceWeigher.new,
        Agents::DisagreementDetector.new,
        mock_writer.new
      ]
    end

    assert_difference("Article.count", 1) do
      result = pipeline.run!

      article = result[:article]
      assert article.persisted?
      assert_equal "published", article.status
      assert article.metadata["agents"].length >= 5

      # Verify agent names are logged
      agent_names = article.metadata["agents"].map { |a| a["name"] }
      assert_includes agent_names, "Relevance Analyst"
      assert_includes agent_names, "Authority Evaluator"
      assert_includes agent_names, "Evidence Weigher"
      assert_includes agent_names, "Disagreement Detector"
    end
  end
end
