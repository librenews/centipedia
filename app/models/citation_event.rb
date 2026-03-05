class CitationEvent < ApplicationRecord
  belongs_to :source
  belongs_to :topic
  belongs_to :user

  validates :event_type, presence: true
  validates :url_base_score, :domain_multiplier, :corroboration_multiplier, :total_weight, numericality: true
  validates :rubric_version, presence: true
end
