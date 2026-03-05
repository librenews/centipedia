require "test_helper"

class DisagreementDetectorTest < ActiveSupport::TestCase
  setup do
    @topic = topics(:one)
    @user = users(:alice)
    @domain = domains(:one)
  end

  test "detects numerical disagreements between sources" do
    source_a = Source.create!(canonical_url: "https://a.example.com/1", domain: @domain, status: "live",
      article_content: "Inflation was reported at 3.1% this quarter.")
    source_b = Source.create!(canonical_url: "https://b.example.com/1", domain: @domain, status: "live",
      article_content: "Inflation reached 3.4% according to new data.")

    ce_a = CitationEvent.create!(source: source_a, topic: @topic, user: @user,
      event_type: "submitted", url_base_score: 5, domain_multiplier: 1, corroboration_multiplier: 1,
      total_weight: 5, rubric_version: "1.0.0")
    ce_b = CitationEvent.create!(source: source_b, topic: @topic, user: @user,
      event_type: "submitted", url_base_score: 5, domain_multiplier: 1, corroboration_multiplier: 1,
      total_weight: 5, rubric_version: "1.0.0")

    agent = Agents::DisagreementDetector.new
    context = { topic: @topic, citations: [ ce_a, ce_b ], disagreements: [] }

    result = agent.run(context)

    assert result[:disagreements].any?, "Expected disagreements to be detected"
    disagreement = result[:disagreements].first
    assert_includes disagreement["description"], "3.1"
    assert_includes disagreement["description"], "3.4"
  end

  test "reports no disagreements for consistent sources" do
    source_a = Source.create!(canonical_url: "https://a.example.com/2", domain: @domain, status: "live",
      article_content: "The population grew steadily this year.")
    source_b = Source.create!(canonical_url: "https://b.example.com/2", domain: @domain, status: "live",
      article_content: "Economic indicators were positive.")

    ce_a = CitationEvent.create!(source: source_a, topic: @topic, user: @user,
      event_type: "submitted", url_base_score: 5, domain_multiplier: 1, corroboration_multiplier: 1,
      total_weight: 5, rubric_version: "1.0.0")
    ce_b = CitationEvent.create!(source: source_b, topic: @topic, user: @user,
      event_type: "submitted", url_base_score: 5, domain_multiplier: 1, corroboration_multiplier: 1,
      total_weight: 5, rubric_version: "1.0.0")

    agent = Agents::DisagreementDetector.new
    context = { topic: @topic, citations: [ ce_a, ce_b ], disagreements: [] }

    result = agent.run(context)

    assert_empty result[:disagreements]
  end
end
