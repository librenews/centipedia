class TopicsController < ApplicationController
  def index
    @topics = Topic.all.order(created_at: :desc)
  end

  def show
    @topic = Topic.find_by!(slug: params[:slug])
    @citations = @topic.citation_events.includes(source: :domain).order(total_weight: :desc)
  end
end
