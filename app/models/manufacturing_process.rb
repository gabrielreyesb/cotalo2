class ManufacturingProcess < ApplicationRecord
  belongs_to :user
  belongs_to :unit, optional: true
  
  validates :name, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true
  validates :user, presence: true
  
  # Scope to find manufacturing processes belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
end
