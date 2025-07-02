class PriceMargin < ApplicationRecord
  belongs_to :user
  
  validates :min_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :margin_percentage, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  
  validate :max_price_greater_than_min_price
  validate :no_overlapping_ranges
  
  private
  
  def max_price_greater_than_min_price
    return if min_price.blank? || max_price.blank?
    
    if max_price <= min_price
      errors.add(:max_price, :greater_than_min_price)
    end
  end
  
  def no_overlapping_ranges
    return if min_price.blank? || max_price.blank?
    
    overlapping = user.price_margins.where.not(id: id).where(
      "(min_price <= ? AND max_price >= ?) OR (min_price <= ? AND max_price >= ?)",
      max_price, min_price, max_price, max_price
    )
    
    if overlapping.exists?
      errors.add(:base, :overlapping_ranges)
    end
  end
end
