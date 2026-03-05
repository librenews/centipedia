module Agents
  # Scores how closely each source's content relates to the topic.
  # In MVP, this uses simple keyword matching. In production, this would
  # use LLM-scored semantic similarity.
  class RelevanceAnalyst < BaseAgent
    def name = "Relevance Analyst"
    def description = "Scores semantic relevance of each source to the topic"

    def run(context)
      topic = context[:topic]
      citations = context[:citations]

      scores = citations.map do |ce|
        source = ce.source
        content = source.article_content || ""
        title = topic.title.downcase

        # MVP heuristic: count keyword mentions
        mention_count = content.downcase.scan(title).length
        relevance = [ mention_count * 0.15, 1.0 ].min
        depth = content.length > 1000 ? 0.7 : 0.4

        {
          citation_event_id: ce.id,
          relevance_score: relevance.round(2),
          depth_of_coverage: depth.round(2)
        }
      end

      context.merge(relevance_scores: scores)
    end
  end
end
