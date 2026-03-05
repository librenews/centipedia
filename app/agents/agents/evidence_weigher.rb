module Agents
  # Combines scores from RelevanceAnalyst and AuthorityEvaluator
  # using the V1 Rubric formula to produce the final total_weight.
  # Updates each CitationEvent with the computed scores.
  class EvidenceWeigher < BaseAgent
    def name = "Evidence Weigher"
    def description = "Combines agent scores using the V1 Rubric formula"

    def run(context)
      citations = context[:citations]
      relevance_scores = context[:relevance_scores] || []
      authority_scores = context[:authority_scores] || []

      # Build lookup hashes
      relevance_map = relevance_scores.each_with_object({}) { |s, h| h[s[:citation_event_id]] = s }
      authority_map = authority_scores.each_with_object({}) { |s, h| h[s[:citation_event_id]] = s }

      citations.each do |ce|
        rel = relevance_map.dig(ce.id, :relevance_score) || 0.5
        depth = relevance_map.dig(ce.id, :depth_of_coverage) || 0.5
        auth = authority_map.dig(ce.id, :authority_score) || 0.5

        # V1 Rubric: URL Base Score (from relevance + depth) × Domain Multiplier (authority) × Corroboration
        url_base = ((rel * 6.0) + (depth * 4.0)).round(2) # Scale to 0-10
        domain_mult = (auth * 2.0).round(2)                # Scale to 0-2
        corroboration = 1.0                                 # MVP: always 1.0

        total = (url_base * domain_mult * corroboration).round(2)

        ce.update!(
          url_base_score: url_base,
          domain_multiplier: domain_mult,
          corroboration_multiplier: corroboration,
          total_weight: total,
          rubric_version: "1.0.0"
        )

        # Log trust score change
        TrustScore.create!(
          domain: ce.source.domain,
          citation_event: ce,
          score_change: 0.0,
          reason: "Agent pipeline V1 scoring"
        )
      end

      context
    end
  end
end
