# Orchestrates the sequential execution of agents in the Centipedia pipeline.
# Each agent receives a context hash and returns an enriched version of it.
# The pipeline records which agents participated and what they produced.
#
# Usage:
#   pipeline = AgentPipeline.new(topic: topic, citations: citations)
#   result = pipeline.run!
#   result[:article]   # => The persisted Article
#   result[:agent_log] # => Array of agent metadata entries
#
class AgentPipeline
  class PipelineError < StandardError; end

  def initialize(topic:, citations:)
    @topic = topic
    @citations = citations
  end

  def run!
    if @citations.empty?
      raise PipelineError, "No citations available for the pipeline."
    end

    # Build the initial context that flows through all agents
    context = {
      topic: @topic,
      citations: @citations,
      agent_log: [],
      disagreements: []
    }

    # Run each agent in sequence
    agents.each do |agent|
      context = agent.execute(context)
    end

    # Persist the article with agent metadata
    article = @topic.articles.create!(
      content: context[:article_content],
      rubric_version: @citations.first.rubric_version,
      status: "published",
      metadata: {
        "agents" => context[:agent_log],
        "disagreements" => context[:disagreements]
      }
    )

    # Mark previous articles as outdated
    @topic.articles
      .where.not(id: article.id)
      .where(status: "published")
      .update_all(status: "outdated")

    context.merge(article: article)
  end

  private

  # The ordered list of agents in the pipeline.
  # Add or remove agents here to change the pipeline.
  def agents
    [
      Agents::RelevanceAnalyst.new,
      Agents::AuthorityEvaluator.new,
      Agents::EvidenceWeigher.new,
      Agents::DisagreementDetector.new,
      Agents::SynthesisWriter.new
    ]
  end
end
