class RubricScorerService
  # This service applies the V1 Rubric logic defined in doc/rubric_v1.md.
  # For the MVP Phase 2, this is a deterministic stub that generates scores based on simple
  # heuristics until we integrate the AI extraction pipeline in Phase 3.
  #
  # Total Weight = (URL Base Score) × (Domain Multiplier) × (Corroboration Multiplier)

  def initialize(citation_event)
    @event = citation_event
    @source = @event.source
    @domain = @source.domain
  end

  def score!
    # In V1 MVP, before LLM extraction, we generate a baseline score or parse obvious markers.
    url_base = calculate_url_base_score
    domain_mult = calculate_domain_multiplier
    corroboration_mult = calculate_corroboration_multiplier

    total = (url_base * domain_mult * corroboration_mult).round(2)

    @event.update!(
      url_base_score: url_base,
      domain_multiplier: domain_mult,
      corroboration_multiplier: corroboration_mult,
      total_weight: total,
      rubric_version: "1.0.0"
    )

    log_trust_score_change!

    @event
  end

  private

  def calculate_url_base_score
    # In MVP, all submitted URLs get an average baseline score of 5.0 out of 10.0
    # In Phase 3, an AI agent will read @source.content_hash text and assign:
    # Primary Source (+4), Logical Density (+3), Neutral Tone (+2), Freshness (+1)

    if @source.canonical_url.include?(".gov/") || @source.canonical_url.include?(".edu/")
      # Heuristic: government or educational domains get a primary source bump
      7.0
    else
      5.0
    end
  end

  def calculate_domain_multiplier
    # Returns the Domain's emergent reputation modifier. Defaults to 1.0.
    @domain.reputation_modifier || 1.0
  end

  def calculate_corroboration_multiplier
    # In MVP, this is 1.0 unless we detect exact duplicate Sources in the same Topic from different submitters
    # In Phase 3, this will use AI claim-matching across different domains.
    1.0
  end

  def log_trust_score_change!
    # In later versions, Domain reputation will be dynamically altered here.
    # For now, we seed the audit log.
    TrustScore.create!(
      domain: @domain,
      citation_event: @event,
      score_change: 0.0,
      reason: "Initial V1 MVP Scoring Event"
    )
  end
end
