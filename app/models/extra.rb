class Extra < ApplicationRecord
  belongs_to :user
  belongs_to :unit, optional: true
  
  validates :name, presence: { message: "El nombre es requerido" }
  validates :cost, presence: { message: "El costo es requerido" }, numericality: { greater_than_or_equal_to: 0 }
  validates :user, presence: { message: "El usuario es requerido" }
  
  # Scope to find extras belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
end
