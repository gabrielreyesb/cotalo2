class ManufacturingProcess < ApplicationRecord
  belongs_to :user
  belongs_to :unit, optional: true
  
  validates :name, presence: true
  validates :cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true
  validates :user, presence: true
  validates :side, presence: true, inclusion: { in: %w[front back both] }
  
  # Scope to find manufacturing processes belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
  
  # Available side options
  def self.side_options
    [
      { value: 'front', label: 'Frente' },
      { value: 'back', label: 'Reverso' },
      { value: 'both', label: 'Ambas' }
    ]
  end
  
  # Get the display label for the current side
  def side_label
    self.class.side_options.find { |option| option[:value] == side }&.dig(:label) || side
  end
  
  # Check if the process applies to both sides
  def both_sides?
    side == 'both'
  end
  
  # Calculate the multiplier for pricing based on side
  def side_multiplier
    both_sides? ? 2 : 1
  end
end
