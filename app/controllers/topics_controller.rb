class TopicsController < ApplicationController
  before_action :require_authentication, only: [ :new, :create, :synthesize ]

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

  def new
    @topic = Topic.new
  end

  def create
    @topic = Topic.new(topic_params)
    @topic.slug = @topic.title.parameterize if @topic.title.present?

    if @topic.save
      redirect_to topic_path(@topic), notice: "Topic \"#{@topic.title}\" created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def synthesize
    @topic = Topic.find_by!(slug: params[:slug])

    citations = @topic.citation_events
      .where.not(total_weight: nil)
      .includes(source: :domain)
      .order(total_weight: :desc)
      .limit(20)

    pipeline = AgentPipeline.new(topic: @topic, citations: citations)
    pipeline.run!

    redirect_to topic_path(@topic), notice: "Synthesis complete! The article has been updated."
  rescue AgentPipeline::PipelineError, BaseAgent::AgentError => e
    redirect_to topic_path(@topic), alert: "Synthesis failed: #{e.message}"
  end

  private

  def topic_params
    params.require(:topic).permit(:title, :description)
  end
end
