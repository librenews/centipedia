class TopicsController < ApplicationController
  def index
    @topics = Topic.all.order(created_at: :desc)
  end

  def show
    @topic = Topic.find_by!(slug: params[:slug])
    @citations = @topic.citation_events.includes(source: :domain, user: []).order(total_weight: :desc)
    @article = @topic.articles.where(status: "published").order(created_at: :desc).first

    # Build a lookup: citation_event_id => footnote number (1-indexed)
    @citation_index = {}
    @citations.each_with_index { |ce, i| @citation_index[ce.id] = i + 1 }
  end
end
