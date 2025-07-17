class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_products, dependent: :destroy
  has_many :products, through: :quote_products
  has_many :invoices, dependent: :destroy
  
  def self.human_attribute_name(attr, options = {})
    # This can be removed if you are using I18n for attribute names
    super
  end
  
  validates :quote_number, presence: true, uniqueness: true
  validates :project_name, presence: true
  validates :customer_name, presence: true
  validates :organization, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  before_validation :generate_quote_number, on: :create
  
  # Scope to find quotes belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
  
  def total
    quote_products.sum do |quote_product|
      product = quote_product.product
      unit_price = product.pricing.try(:[], "final_price_per_piece") || 0
      unit_price * quote_product.quantity
    end
  end
  
  def create_invoice
    Invoice.create_from_quote(self)
  end
  
  # Public method to access quote data
  def quote_data
    self['data'] ||= self.class.default_data
  end
  
  # Calculate totals for the quote
  def calculate_totals
    subtotal = 0
    
    # Calculate totals from products
    quote_products.includes(:product).each do |quote_product|
      product = quote_product.product
      product_price = product.pricing['total_price'].to_f
      product_quantity = quote_product.quantity
      
      subtotal += product_price * product_quantity
    end
    
    # Get tax percentage (default 16% - Mexico)
    tax_percentage = quote_data['totals']['tax_percentage'].to_f
    
    # Calculate tax amount
    tax_amount = subtotal * (tax_percentage / 100)
    
    # Calculate total
    total = subtotal + tax_amount
    
    # Update data hash
    quote_data['totals'] = {
      'subtotal' => subtotal,
      'tax_percentage' => tax_percentage,
      'tax_amount' => tax_amount,
      'total' => total
    }
    
    # Save the changes
    save
  end
  
  # Get product names for display
  def product_names
    products.pluck(:description).join(", ")
  end
  
  private
  
  def generate_quote_number
    return if quote_number.present?
    
    # Get the last quote number for this specific user
    last_quote = user.quotes.order(created_at: :desc).first
    last_number = last_quote&.quote_number&.split('-')&.last&.to_i || 0
    
    # Generate new quote number
    self.quote_number = "COT-#{Time.current.strftime('%Y%m')}-#{format('%04d', last_number + 1)}"
  end
  
  # Default data structure
  def self.default_data
    {
      products: [],  # Will contain objects with product_id, quantity, etc.
      totals: {
        subtotal: 0,
        tax_percentage: 16, # Default VAT in Mexico
        tax_amount: 0,
        total: 0
      }
    }
  end
  
  # Add a product to the quote
  def add_product(product_id, quantity = 1)
    begin
      # Find the product
      product = user.products.find_by(id: product_id)
      return false unless product
      
      # Check if the product is already in the quote
      existing = quote_products.find_by(product_id: product_id)
      
      if existing
        # Update quantity
        existing.update(quantity: existing.quantity + quantity)
      else
        # Add new product
        quote_products.create(product_id: product_id, quantity: quantity)
      end
      
      # Recalculate totals
      calculate_totals
      return true
    rescue => e
      Rails.logger.error("Error adding product to quote: #{e.message}")
      return false
    end
  end
  
  # Update product quantity
  def update_product_quantity(product_id, quantity)
    begin
      quote_product = quote_products.find_by(product_id: product_id)
      return false unless quote_product
      
      if quantity <= 0
        # Remove product if quantity is zero or negative
        quote_product.destroy
      else
        # Update quantity
        quote_product.update(quantity: quantity)
      end
      
      # Recalculate totals
      calculate_totals
      return true
    rescue => e
      Rails.logger.error("Error updating product quantity: #{e.message}")
      return false
    end
  end
  
  # Remove a product from the quote
  def remove_product(product_id)
    begin
      quote_product = quote_products.find_by(product_id: product_id)
      return false unless quote_product
      
      quote_product.destroy
      
      # Recalculate totals
      calculate_totals
      return true
    rescue => e
      Rails.logger.error("Error removing product from quote: #{e.message}")
      return false
    end
  end
end
