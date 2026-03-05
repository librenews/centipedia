class RubricController < ApplicationController
  def index
    markdown_text = File.read(Rails.root.join("doc", "rubric_v1.md"))
    renderer = Redcarpet::Render::HTML.new(hard_wrap: true, safe_links_only: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, strikethrough: true)

    @rubric_html = markdown.render(markdown_text).html_safe
  end
end
