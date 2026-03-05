class TrustScore < ApplicationRecord
  belongs_to :domain
  belongs_to :citation_event, optional: true # not all trust scores stem from a specific single event

  validates :score_change, numericality: true, presence: true
  validates :reason, presence: true
end
