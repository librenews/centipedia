require "test_helper"

class RubricScorerServiceTest < ActiveSupport::TestCase
  setup do
    @topic = topics(:one)
    @domain = domains(:one)
    @domain.update!(reputation_modifier: 1.2)
    @source = sources(:one)
    @source.update!(domain: @domain, canonical_url: "https://example.com/regular")
    @user = users(:alice)

    @citation_event = CitationEvent.create!(
      topic: @topic,
      source: @source,
      user: @user,
      event_type: "submitted",
      url_base_score: 0.0,
      domain_multiplier: 0.0,
      corroboration_multiplier: 0.0,
      total_weight: 0.0,
      rubric_version: "pending"
    )
  end

  test "scores a regular url citation event" do
    service = RubricScorerService.new(@citation_event)
    service.score!

    @citation_event.reload
    assert_equal 5.0, @citation_event.url_base_score
    assert_equal 1.2, @citation_event.domain_multiplier
    assert_equal 1.0, @citation_event.corroboration_multiplier
    assert_equal 6.0, @citation_event.total_weight
    assert_equal "1.0.0", @citation_event.rubric_version

    assert_equal 1, TrustScore.where(citation_event: @citation_event).count
  end

  test "gives a higher url base score for edu domains" do
    @source.update!(canonical_url: "https://university.edu/study.pdf")

    service = RubricScorerService.new(@citation_event)
    service.score!

    @citation_event.reload
    assert_equal 7.0, @citation_event.url_base_score
    assert_equal 1.2, @citation_event.domain_multiplier
    assert_equal 1.0, @citation_event.corroboration_multiplier
    assert_equal 8.4, @citation_event.total_weight
  end

  test "gives a higher url base score for gov domains" do
    @source.update!(canonical_url: "https://whitehouse.gov/report")

    service = RubricScorerService.new(@citation_event)
    service.score!

    @citation_event.reload
    assert_equal 7.0, @citation_event.url_base_score
    assert_equal 1.2, @citation_event.domain_multiplier
    assert_equal 1.0, @citation_event.corroboration_multiplier
    assert_equal 8.4, @citation_event.total_weight
  end
end
