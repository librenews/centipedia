class Domain < ApplicationRecord
  has_many :sources, dependent: :destroy

  validates :host, presence: true, uniqueness: true
  validates :reputation_modifier, numericality: { greater_than_or_equal_to: 0.0 }
end
