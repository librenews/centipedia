require "nokogiri"
require "httparty"

class UrlFetcherService
  class FetchError < StandardError; end

  def initialize(url)
    @url = url
  end

  def fetch_and_extract
    response = HTTParty.get(@url, headers: default_headers, timeout: 10)

    unless response.success?
      raise FetchError, "Failed to fetch URL. HTTP Status: #{response.code}"
    end

    html = response.body
    doc = Nokogiri::HTML(html)

    # Remove script and style tags
    doc.search("script, style, nav, footer, header, aside, form, iframe").remove

    # Extract Title
    title = doc.title || ""

    # Extract Meta description
    meta_desc_tag = doc.at('meta[name="description"]') || doc.at('meta[property="og:description"]')
    description = meta_desc_tag ? meta_desc_tag["content"] : ""

    # Extract Article Body
    # Prioritize standard article tags, then fall back to body
    article_node = doc.at("article") || doc.at("main") || doc.at("body")

    text_content = if article_node
      # Get all text blocks, normalize whitespace
      article_node.text.gsub(/\s+/, " ").strip
    else
      ""
    end

    {
      title: title.strip,
      description: description.strip,
      text: text_content
    }
  rescue HTTParty::Error, SocketError, Timeout::Error => e
    raise FetchError, "Network error while fetching URL: #{e.message}"
  end

  private

  def default_headers
    {
      "User-Agent" => "Centipedia/1.0 (+http://centipedia.local)",
      "Accept" => "text/html,application/xhtml+xml"
    }
  end
end
