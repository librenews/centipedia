class Article < ApplicationRecord
  belongs_to :topic

  validates :content, presence: true
  validates :rubric_version, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published outdated] }
end
