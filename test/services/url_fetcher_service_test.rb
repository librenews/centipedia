require "test_helper"

class UrlFetcherServiceTest < ActiveSupport::TestCase
  setup do
    @url = "https://example.com/article"
    @html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Test Article Title</title>
        <meta name="description" content="This is a test description.">
      </head>
      <body>
        <header>Header content to ignore</header>
        <main>
          <h1>Test Article Title</h1>
          <p>This is the main body of the article.</p>
          <script>console.log("Ignore scripts")</script>
        </main>
        <footer>Footer content to ignore</footer>
      </body>
      </html>
    HTML
  end

  test "successfully fetches and extracts content" do
    stub_request(:get, @url)
      .to_return(status: 200, body: @html_content, headers: { "Content-Type" => "text/html" })

    service = UrlFetcherService.new(@url)
    result = service.fetch_and_extract

    assert_equal "Test Article Title", result[:title]
    assert_equal "This is a test description.", result[:description]
    # The main block should have its content extracted, but script tags ignored
    assert_includes result[:text], "Test Article Title"
    assert_includes result[:text], "This is the main body of the article."
    assert_not_includes result[:text], "Ignore scripts"
    assert_not_includes result[:text], "Footer content to ignore"
    assert_not_includes result[:text], "Header content to ignore"
  end

  test "handles 404 responses gracefully" do
    stub_request(:get, @url).to_return(status: 404)

    service = UrlFetcherService.new(@url)

    error = assert_raises(UrlFetcherService::FetchError) do
      service.fetch_and_extract
    end

    assert_includes error.message, "Failed to fetch URL"
    assert_includes error.message, "404"
  end

  test "handles network timeouts gracefully" do
    stub_request(:get, @url).to_raise(Timeout::Error)

    service = UrlFetcherService.new(@url)

    error = assert_raises(UrlFetcherService::FetchError) do
      service.fetch_and_extract
    end

    assert_includes error.message, "Network error"
  end
end
