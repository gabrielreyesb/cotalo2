class Material < ApplicationRecord
  belongs_to :unit, optional: true
  belongs_to :user
  has_many :product_materials
  has_many :products, through: :product_materials
  
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true
  validates :ancho, presence: true, numericality: { greater_than: 0 }
  validates :largo, presence: true, numericality: { greater_than: 0 }
  validates :user, presence: true

  # Scope to find materials belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
end
