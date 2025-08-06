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

  # Check if this material uses weight-based pricing (kg, g, gr, etc.)
  def weight_based_pricing?
    unit_name = unit&.name&.downcase || ''
    unit_abbr = unit&.abbreviation&.downcase || ''
    
    # Check for weight units (exact matches to avoid false positives)
    weight_units = ['kg', 'g', 'gr', 'gramo', 'gramos', 'kilo', 'kilos', 'kilogramo', 'kilogramos']
    weight_units.any? { |wu| unit_name == wu || unit_abbr == wu }
  end

  # Check if this material uses area-based pricing (m²)
  def area_based_pricing?
    unit_name = unit&.name&.downcase || ''
    unit_abbr = unit&.abbreviation&.downcase || ''
    
    # Check for area units
    area_units = ['m2', 'mt2', 'm²', 'mt²', 'metro cuadrado', 'metros cuadrados']
    area_units.any? { |au| unit_name.include?(au) || unit_abbr.include?(au) }
  end
end
