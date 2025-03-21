class Quote < ApplicationRecord
  belongs_to :user
  has_many :quote_products, dependent: :destroy
  has_many :products, through: :quote_products
  
  validates :quote_number, presence: true, uniqueness: { scope: :user_id }
  validates :project_name, presence: true
  validates :customer_name, presence: true
  validates :organization, presence: true
  
  before_validation :set_quote_number, on: :create
  
  # Scope to find quotes belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
  
  # Generate a unique quote number
  def set_quote_number
    return if quote_number.present?
    
    # Format: COT-YYYYMMDD-XXXX where XXXX is a sequential number
    date_part = Date.today.strftime('%Y%m%d')
    
    # Find the latest quote number for today
    latest_quote = Quote.where("quote_number LIKE ?", "COT-#{date_part}-%").order(quote_number: :desc).first
    
    if latest_quote
      # Extract the sequential part and increment
      seq_number = latest_quote.quote_number.split('-').last.to_i + 1
    else
      # Start with 1
      seq_number = 1
    end
    
    # Format the sequential part with leading zeros
    seq_part = seq_number.to_s.rjust(4, '0')
    
    # Set the quote number
    self.quote_number = "COT-#{date_part}-#{seq_part}"
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
    tax_percentage = data['totals']['tax_percentage'].to_f
    
    # Calculate tax amount
    tax_amount = subtotal * (tax_percentage / 100)
    
    # Calculate total
    total = subtotal + tax_amount
    
    # Update data hash
    data['totals'] = {
      'subtotal' => subtotal,
      'tax_percentage' => tax_percentage,
      'tax_amount' => tax_amount,
      'total' => total
    }
    
    # Save the changes
    save
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
  
  # Initialize data hash if it's nil
  def data
    self['data'] ||= self.class.default_data
  end
end
