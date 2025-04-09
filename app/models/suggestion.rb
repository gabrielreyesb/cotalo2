class Suggestion < ApplicationRecord
  belongs_to :user, optional: true
  validates :content, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
end 