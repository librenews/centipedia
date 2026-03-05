require "uri"

class CitationSubmissionService
  class SubmissionError < StandardError; end

  def initialize(url:, topic:, user:)
    @url = url.strip
    @topic = topic
    @user = user
  end

  def submit!
    validate_url!

    domain = find_or_create_domain
    source = find_or_create_source(domain)

    # Fetch and persist the article content
    fetcher = UrlFetcherService.new(@url)
    fetcher.fetch_and_persist!(source)

    # Create the citation event (initially with placeholder scores)
    citation_event = CitationEvent.create!(
      source: source,
      topic: @topic,
      user: @user,
      event_type: "submitted",
      url_base_score: 0.0,
      domain_multiplier: 0.0,
      corroboration_multiplier: 0.0,
      total_weight: 0.0,
      rubric_version: "pending"
    )

    # Score the citation using the rubric
    scorer = RubricScorerService.new(citation_event)
    scorer.score!

    citation_event.reload
  end

  private

  def validate_url!
    uri = URI.parse(@url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      raise SubmissionError, "Invalid URL. Must be an HTTP or HTTPS URL."
    end
  rescue URI::InvalidURIError
    raise SubmissionError, "Invalid URL format."
  end

  def find_or_create_domain
    host = URI.parse(@url).host
    Domain.find_or_create_by!(host: host)
  end

  def find_or_create_source(domain)
    Source.find_or_create_by!(canonical_url: @url) do |source|
      source.domain = domain
      source.status = "pending"
    end
  end
end
