class Material < ApplicationRecord
  belongs_to :unit
  belongs_to :user
  has_many :product_materials
  has_many :products, through: :product_materials
  
  validates :client_description, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true
  validates :user, presence: true
  validates :ancho, numericality: { greater_than: 0 }, allow_nil: true
  validates :largo, numericality: { greater_than: 0 }, allow_nil: true

  # Scope to find materials belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
end
