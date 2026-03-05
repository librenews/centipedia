require "test_helper"

class CitationSubmissionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @topic = topics(:one)

    @html_body = <<~HTML
      <html>
        <head><title>Test Article</title>
        <meta name="description" content="A test description.">
        </head>
        <body>
          <article>This is the main content of the test article.</article>
        </body>
      </html>
    HTML
  end

  test "full pipeline: creates domain, source, fetches, scores, and returns citation event" do
    url = "https://example.com/test-article"

    stub_request(:get, url).to_return(status: 200, body: @html_body, headers: { "Content-Type" => "text/html" })

    service = CitationSubmissionService.new(url: url, topic: @topic, user: @user)
    citation = service.submit!

    assert citation.persisted?
    assert_equal @topic, citation.topic
    assert_equal @user, citation.user
    assert_equal "submitted", citation.event_type
    assert_equal "1.0.0", citation.rubric_version

    # Source was created
    source = citation.source
    assert_equal url, source.canonical_url
    assert_equal "live", source.status
    assert source.article_content.present?
    assert source.content_hash.present?

    # Domain was created
    domain = source.domain
    assert_equal "example.com", domain.host

    # Scoring occurred
    assert citation.total_weight > 0
    assert citation.url_base_score > 0
  end

  test "deduplicates source by canonical URL" do
    url = "https://unique-dedup-test.org/existing-article"
    domain = Domain.create!(host: "unique-dedup-test.org")
    existing_source = Source.create!(canonical_url: url, domain: domain, status: "live")

    stub_request(:get, url).to_return(status: 200, body: @html_body, headers: { "Content-Type" => "text/html" })

    service = CitationSubmissionService.new(url: url, topic: @topic, user: @user)
    citation = service.submit!

    assert_equal existing_source.id, citation.source.id
  end

  test "rejects invalid URL" do
    service = CitationSubmissionService.new(url: "not-a-url", topic: @topic, user: @user)

    error = assert_raises(CitationSubmissionService::SubmissionError) do
      service.submit!
    end

    assert_includes error.message, "Invalid URL"
  end

  test "rejects non-HTTP URL" do
    service = CitationSubmissionService.new(url: "ftp://files.example.com/doc", topic: @topic, user: @user)

    error = assert_raises(CitationSubmissionService::SubmissionError) do
      service.submit!
    end

    assert_includes error.message, "Invalid URL"
  end

  test "handles fetch failure gracefully" do
    url = "https://broken.example.com/404"

    stub_request(:get, url).to_return(status: 404, body: "Not Found")

    service = CitationSubmissionService.new(url: url, topic: @topic, user: @user)

    assert_raises(UrlFetcherService::FetchError) do
      service.submit!
    end
  end
end
