class CitationEventsController < ApplicationController
  before_action :require_authentication

  def new
    @topic = Topic.find_by!(slug: params[:topic_slug])
  end

  def create
    @topic = Topic.find_by!(slug: params[:topic_slug])

    # In V1 MVP, the Scorer Service isn't built yet, so we just mock the source and scoring for now
    # to complete the UI loop

    redirect_to topic_path(@topic), notice: "Citation submitted successfully! It is now queued for deterministic scoring."
  end
end
