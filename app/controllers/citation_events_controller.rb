class CitationEventsController < ApplicationController
  before_action :require_authentication

  def new
    @topic = Topic.find_by!(slug: params[:topic_slug])
  end

  def create
    @topic = Topic.find_by!(slug: params[:topic_slug])

    service = CitationSubmissionService.new(
      url: params[:canonical_url],
      topic: @topic,
      user: current_user
    )

    citation_event = service.submit!

    redirect_to topic_path(@topic), notice: "Citation submitted and scored! Weight: #{citation_event.total_weight}"
  rescue CitationSubmissionService::SubmissionError, UrlFetcherService::FetchError => e
    redirect_to new_topic_citation_event_path(@topic), alert: "Submission failed: #{e.message}"
  end
end
