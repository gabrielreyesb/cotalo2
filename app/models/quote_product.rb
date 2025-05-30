class QuoteProduct < ApplicationRecord
  belongs_to :quote
  belongs_to :product
  
  validates :quantity, presence: { message: "La cantidad es requerida" }, numericality: { greater_than: 0, only_integer: true }
  
  after_create :update_quote_totals
  after_update :update_quote_totals
  after_destroy :update_quote_totals
  
  private
  
  def update_quote_totals
    quote.calculate_totals
  end
end 