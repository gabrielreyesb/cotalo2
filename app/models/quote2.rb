class Quote2 < ApplicationRecord
  belongs_to :user
  
  validates :client_name, presence: true
  validates :client_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :description, presence: true
  validates :quote_number, presence: true, uniqueness: { scope: :user_id }
  validates :user, presence: true
  
  validate :validate_product_data
  
  before_validation :generate_quote_number, on: :create
  
  # Scope to find quotes belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
  
  # Return a formatted description with price for display in lists
  def formatted_description
    price = pricing["total_price"] || 0
    "#{description} - $#{format('%.2f', price)} (#{client_name})"
  end
  
  # Define structure of our product data hash with default values (similar to Product model)
  def self.default_product_data
    {
      general_info: {
        width: nil,
        length: nil,
        inner_measurements: nil,
        quantity: 1,
        comments: ""
      },
      materials: [],  # Will contain objects with the structure shown in Product.material_template
      processes: [],  # Will contain objects with the structure shown in Product.process_template
      extras: [],     # Will contain objects with the structure shown in Product.extra_template
      pricing: {
        materials_cost: 0,
        material_processes_cost: 0,
        global_processes_cost: 0,
        processes_cost: 0,
        extras_cost: 0,
        subtotal: 0,
        waste_percentage: nil, # Will use user's config if nil
        waste_value: 0,
        price_per_piece_before_margin: 0,
        margin_percentage: nil, # Will use user's config if nil
        margin_value: 0,
        total_price: 0,
        final_price_per_piece: 0
      }
    }
  end
  
  # Initialize with default structure if product_data is empty
  after_initialize do
    self.product_data = self.class.default_product_data.merge(product_data) if product_data.empty?
  end
  
  # Getters for each section of product data
  def general_info
    product_data["general_info"] || product_data[:general_info] || {}
  end
  
  def materials
    product_data["materials"] || product_data[:materials] || []
  end
  
  def processes
    product_data["processes"] || product_data[:processes] || []
  end
  
  def extras
    product_data["extras"] || product_data[:extras] || []
  end
  
  def pricing
    product_data["pricing"] || product_data[:pricing] || {}
  end
  
  # Setters for each section
  def general_info=(value)
    self.product_data = product_data.merge("general_info" => value)
  end
  
  def materials=(value)
    self.product_data = product_data.merge("materials" => value)
  end
  
  def processes=(value)
    self.product_data = product_data.merge("processes" => value)
  end
  
  def extras=(value)
    self.product_data = product_data.merge("extras" => value)
  end
  
  def pricing=(value)
    self.product_data = product_data.merge("pricing" => value)
  end
  
  # Calculate totals based on materials, processes, and extras (similar to Product model)
  def calculate_totals
    # Calculate materials cost - use the cost field from the saved data
    materials_cost = materials.sum do |m| 
      # Try different possible field names for material cost
      cost = m["cost"] || m["totalPrice"] || m["subtotal_price"] || 0
      cost.to_f
    end
    
    # Calculate material processes cost and global processes cost separately
    material_processes_cost = calculate_material_processes_cost
    global_processes_cost = calculate_global_processes_cost
    processes_cost = material_processes_cost + global_processes_cost
    
    # Calculate extras cost - use the cost field from the saved data
    extras_cost = extras.sum do |e| 
      # Try different possible field names for extra cost
      cost = e["cost"] || e["subtotal_price"] || e["total"] || 0
      cost.to_f
    end
    
    # Calculate subtotal
    subtotal = materials_cost + processes_cost + extras_cost
    
    # Get waste percentage (from quote or user default)
    waste_pct = pricing["waste_percentage"] || pricing[:waste_percentage] || user.waste_percentage
    
    # Calculate waste value
    waste_value = subtotal * (waste_pct / 100.0)
    
    # Calculate price per piece before margin
    quantity = general_info["quantity"].to_i
    quantity = 1 if quantity <= 0
    price_per_piece_before_margin = (subtotal + waste_value) / quantity
    
    # Calculate total before margin (subtotal + waste)
    total_before_margin = subtotal + waste_value
    
    # Get margin percentage
    margin_pct = if pricing["margin_percentage"].present? || pricing[:margin_percentage].present?
      pricing["margin_percentage"] || pricing[:margin_percentage]
    else
      calculate_margin_percentage(total_before_margin)
    end
    
    # Calculate margin value
    margin_value = total_before_margin * (margin_pct / 100.0)
    
    # Calculate total price
    total_price = total_before_margin + margin_value
    
    # Calculate final price per piece
    final_price_per_piece = total_price / quantity
    
    # Update pricing data
    self.pricing = pricing.merge(
      "materials_cost" => materials_cost,
      "material_processes_cost" => material_processes_cost,
      "global_processes_cost" => global_processes_cost,
      "processes_cost" => processes_cost,
      "extras_cost" => extras_cost,
      "subtotal" => subtotal,
      "waste_percentage" => waste_pct,
      "waste_value" => waste_value,
      "price_per_piece_before_margin" => price_per_piece_before_margin,
      "margin_percentage" => margin_pct,
      "margin_value" => margin_value,
      "total_price" => total_price,
      "final_price_per_piece" => final_price_per_piece
    )
    
    # Return self for method chaining
    self
  end
  
  private
  
  def generate_quote_number
    return if quote_number.present?
    
    # Get the highest quote number for this specific user in current month
    current_month = Time.current.strftime('%Y%m')
    pattern = "COTV2-#{current_month}-%"
    
    last_quote = user.quote2s.where("quote_number LIKE ?", pattern).order(:quote_number).last
    last_number = if last_quote
      last_quote.quote_number.split('-').last.to_i
    else
      0
    end
    
    # Generate new quote number with V2 prefix
    self.quote_number = "COTV2-#{current_month}-#{format('%04d', last_number + 1)}"
  end
  
  def validate_product_data
    if product_data.nil? || product_data["general_info"].nil?
      errors.add(:base, "Product information is required")
      return
    end
    
    general = product_data["general_info"]
    errors.add(:base, "Product quantity is required") if general["quantity"].blank? || general["quantity"].to_i <= 0
    errors.add(:base, "Product width is required") if general["width"].blank? || general["width"].to_f <= 0
    errors.add(:base, "Product length is required") if general["length"].blank? || general["length"].to_f <= 0
    
    if product_data["materials"].nil? || product_data["materials"].empty?
      errors.add(:base, "At least one material is required")
    end
  end
  
  def calculate_material_processes_cost
    total = 0
    
    # Calculate processes from materials
    materials.each do |material|
      if material["processes"].present?
        material["processes"].each do |process|
          # Use price or cost field, and times or veces field
          price = process["price"] || process["cost"] || 0
          times = process["times"] || process["veces"] || 1
          total += price.to_f * times.to_f
        end
      end
    end
    
    total
  end
  
  def calculate_global_processes_cost
    total = 0
    
    # Calculate global processes from the processes array
    processes.each do |process|
      # Use price or cost field, and times or veces field
      price = process["price"] || process["cost"] || 0
      times = process["times"] || process["veces"] || 1
      total += price.to_f * times.to_f
    end
    
    total
  end
  
  def calculate_margin_percentage(total_before_margin)
    # Find the appropriate price margin based on the total before margin
    price_margin = user.price_margins.where("min_price <= ? AND max_price >= ?", total_before_margin, total_before_margin).first
    price_margin&.margin_percentage || 0
  end
end
