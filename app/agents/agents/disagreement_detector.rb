module Agents
  # Compares claims across sources for the same topic to detect contradictions.
  # In MVP, this uses simple text similarity to find conflicting numerical claims.
  # In production, this would use LLM-based stance detection.
  class DisagreementDetector < BaseAgent
    def name = "Disagreement Detector"
    def description = "Detects contradictions between sources"

    # Simple pattern for numerical claims (percentages, dollar amounts, counts)
    NUMBER_PATTERN = /(\d+\.?\d*)\s*(%|percent|billion|million|thousand|trillion)/i

    def run(context)
      citations = context[:citations]
      disagreements = []

      # Compare each pair of sources
      citation_pairs = citations.to_a.combination(2)

      citation_pairs.each do |ce_a, ce_b|
        content_a = ce_a.source.article_content || ""
        content_b = ce_b.source.article_content || ""

        # Extract numerical claims
        nums_a = content_a.scan(NUMBER_PATTERN)
        nums_b = content_b.scan(NUMBER_PATTERN)

        # Look for same-unit disagreements
        nums_a.each do |val_a, unit_a|
          nums_b.each do |val_b, unit_b|
            next unless unit_a.downcase == unit_b.downcase
            next if val_a == val_b

            disagreements << {
              "source_a_id" => ce_a.source.id,
              "source_b_id" => ce_b.source.id,
              "citation_a_id" => ce_a.id,
              "citation_b_id" => ce_b.id,
              "description" => "Source A claims #{val_a}#{unit_a}, Source B claims #{val_b}#{unit_b}"
            }
          end
        end
      end

      context.merge(disagreements: disagreements.uniq)
    end
  end
end
