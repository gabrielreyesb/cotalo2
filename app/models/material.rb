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
  validates :weight, numericality: { greater_than: 0 }, if: :weight_based_pricing?

  # Scope to find materials belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }

  # Check if this material uses weight-based pricing (grs/m²)
  def weight_based_pricing?
    unit&.name&.downcase&.include?('grs/m2') || unit&.abbreviation&.downcase&.include?('grs/m2')
  end

  # Check if this material uses area-based pricing (m²)
  def area_based_pricing?
    unit&.name&.downcase&.include?('m2') || unit&.name&.downcase&.include?('mt2') || 
    unit&.abbreviation&.downcase&.include?('m2') || unit&.abbreviation&.downcase&.include?('mt2')
  end
end
