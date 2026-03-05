class Topic < ApplicationRecord
  has_many :citation_events, dependent: :destroy
  has_many :sources, through: :citation_events

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true

  def to_param
    slug
  end
end
