class Source < ApplicationRecord
  belongs_to :domain
  has_many :citation_events, dependent: :destroy

  validates :canonical_url, presence: true, uniqueness: true
  validates :status, presence: true
end
