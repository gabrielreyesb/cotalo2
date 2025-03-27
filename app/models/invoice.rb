class Invoice < ApplicationRecord
  belongs_to :quote
  
  validates :status, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Status constants
  STATUS_DRAFT = 'draft'
  STATUS_PENDING = 'pending'
  STATUS_CREATED = 'created'
  STATUS_CANCELLED = 'cancelled'
  
  # Valid status values
  VALID_STATUSES = [STATUS_DRAFT, STATUS_PENDING, STATUS_CREATED, STATUS_CANCELLED]
  
  validates :status, inclusion: { in: VALID_STATUSES }
  
  # Scopes
  scope :draft, -> { where(status: STATUS_DRAFT) }
  scope :pending, -> { where(status: STATUS_PENDING) }
  scope :created, -> { where(status: STATUS_CREATED) }
  scope :cancelled, -> { where(status: STATUS_CANCELLED) }
  
  # Class methods
  def self.create_from_quote(quote)
    # Calculate total from quote products
    total = quote.quote_products.sum do |quote_product|
      product = quote_product.product
      unit_price = product.pricing.try(:[], "final_price_per_piece") || 0
      unit_price * quote_product.quantity
    end
    
    # Create invoice with initial data
    create!(
      quote: quote,
      status: STATUS_DRAFT,
      total: total,
      data: {
        quote_number: quote.quote_number,
        customer_name: quote.customer_name,
        organization: quote.organization,
        email: quote.email,
        telephone: quote.telephone,
        products: quote.quote_products.map do |quote_product|
          product = quote_product.product
          {
            description: product.description,
            quantity: quote_product.quantity,
            unit_price: product.pricing.try(:[], "final_price_per_piece") || 0,
            total: (product.pricing.try(:[], "final_price_per_piece") || 0) * quote_product.quantity
          }
        end
      }
    )
  end
  
  # Instance methods
  def mark_as_pending!
    update!(status: STATUS_PENDING)
  end
  
  def mark_as_created!(facturama_id)
    update!(status: STATUS_CREATED, facturama_id: facturama_id)
  end
  
  def mark_as_cancelled!
    update!(status: STATUS_CANCELLED)
  end
  
  def draft?
    status == STATUS_DRAFT
  end
  
  def pending?
    status == STATUS_PENDING
  end
  
  def created?
    status == STATUS_CREATED
  end
  
  def cancelled?
    status == STATUS_CANCELLED
  end
end
