module Agents
  # Evaluates domain credibility and authorship signals.
  # Checks for institutional indicators (.gov, .edu, .org),
  # known high-authority domains, and primary research signals.
  class AuthorityEvaluator < BaseAgent
    def name = "Authority Evaluator"
    def description = "Evaluates domain credibility and authorship signals"

    INSTITUTIONAL_TLDS = %w[.gov .edu .mil].freeze
    HIGH_AUTHORITY_SIGNALS = %w[.org .int].freeze

    def run(context)
      citations = context[:citations]

      scores = citations.map do |ce|
        domain_host = ce.source.domain.host
        signals = []

        authority = 0.5 # baseline

        # Institutional TLD check
        if INSTITUTIONAL_TLDS.any? { |tld| domain_host.end_with?(tld) }
          authority += 0.35
          signals << "institutional_tld"
        end

        # High-authority TLD
        if HIGH_AUTHORITY_SIGNALS.any? { |tld| domain_host.end_with?(tld) }
          authority += 0.15
          signals << "high_authority_tld"
        end

        # Domain reputation modifier from our database
        reputation = ce.source.domain.reputation_modifier || 1.0
        if reputation > 1.0
          authority += 0.1
          signals << "positive_reputation_history"
        elsif reputation < 1.0
          authority -= 0.1
          signals << "negative_reputation_history"
        end

        # Content length as a proxy for depth
        content = ce.source.article_content || ""
        if content.length > 2000
          authority += 0.05
          signals << "substantial_content"
        end

        {
          citation_event_id: ce.id,
          authority_score: [ authority, 1.0 ].min.round(2),
          signals: signals
        }
      end

      context.merge(authority_scores: scores)
    end
  end
end
