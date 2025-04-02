class Product < ApplicationRecord
  belongs_to :user
  has_many :quote_products, dependent: :restrict_with_error
  has_many :quotes, through: :quote_products
  
  validates :description, presence: true
  validates :user, presence: true
  
  # Scope to find products belonging to a specific user
  scope :for_user, ->(user) { where(user: user) }
  
  # Return a formatted description with price for display in lists
  def formatted_description
    price = pricing["total_price"] || 0
    "#{description} - $#{format('%.2f', price)}"
  end
  
  # Define structure of our data hash with default values
  def self.default_data
    {
      general_info: {
        width: nil,
        length: nil,
        inner_measurements: nil,
        quantity: 1,
        comments: ""
      },
      materials: [],  # Will contain objects with the structure shown in self.material_template
      processes: [],  # Will contain objects with the structure shown in self.process_template
      extras: [],     # Will contain objects with the structure shown in self.extra_template
      pricing: {
        materials_cost: 0,
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
  
  # Template for a new material item
  def self.material_template
    {
      "material_id" => nil,            # Reference to the material in the database
      "description" => "",             # Material description
      "price" => 0,                    # Unit price
      "unit" => nil,                   # Unit information (id, name, abbreviation)
      "width" => 0,                    # Width in cm
      "length" => 0,                   # Length in cm
      "quantity" => 0,                 # Number of pieces/units needed
      "pieces_per_material" => 0,      # How many pieces can be cut from one sheet
      "total_sheets" => 0,             # Total sheets needed
      "total_square_meters" => 0,      # Total area in square meters
      "subtotal_price" => 0,           # Subtotal for this material
      "comments" => ""                 # Additional comments about this material
    }
  end
  
  # Template for a new process item
  def self.process_template
    {
      "process_id" => nil,             # Reference to the process in the database
      "description" => "",             # Process description
      "price" => 0,                    # Unit price
      "unit" => nil,                   # Unit information (id, name, abbreviation)
      "quantity" => 0,                 # Number of units/times needed
      "subtotal_price" => 0,           # Subtotal for this process
      "comments" => ""                 # Additional comments about this process
    }
  end
  
  # Template for a new extra item
  def self.extra_template
    {
      "extra_id" => nil,               # Reference to the extra in the database
      "description" => "",             # Extra description
      "price" => 0,                    # Unit price
      "quantity" => 0,                 # Number of units needed
      "subtotal_price" => 0,           # Subtotal for this extra
      "comments" => ""                 # Additional comments about this extra
    }
  end
  
  # Initialize with default structure if data is empty
  after_initialize do
    self.data = self.class.default_data.merge(data) if data.empty?
  end
  
  # Getters for each section of data
  def general_info
    data["general_info"] || data[:general_info] || {}
  end
  
  def materials
    data["materials"] || data[:materials] || []
  end
  
  def processes
    data["processes"] || data[:processes] || []
  end
  
  def extras
    data["extras"] || data[:extras] || []
  end
  
  def pricing
    data["pricing"] || data[:pricing] || {}
  end
  
  # Setters for each section
  def general_info=(value)
    self.data = data.merge("general_info" => value)
  end
  
  def materials=(value)
    self.data = data.merge("materials" => value)
  end
  
  def processes=(value)
    self.data = data.merge("processes" => value)
  end
  
  def extras=(value)
    self.data = data.merge("extras" => value)
  end
  
  def pricing=(value)
    self.data = data.merge("pricing" => value)
  end
  
  # Utility method to get a deep copy of the product (for duplication)
  def deep_clone
    new_product = self.dup
    
    # Create a deep copy of the data hash
    new_data = {
      'general_info' => self.data['general_info'].deep_dup,
      'materials' => self.data['materials'].map(&:deep_dup),
      'processes' => self.data['processes'].map(&:deep_dup),
      'extras' => self.data['extras'].map(&:deep_dup),
      'materials_comments' => self.data['materials_comments'],
      'processes_comments' => self.data['processes_comments'],
      'extras_comments' => self.data['extras_comments'],
      'pricing' => self.data['pricing'].deep_dup,
      'selected_material_id' => self.data['selected_material_id']
    }
    
    new_product.data = new_data
    new_product.description = "#{self.description} (Copia)"
    new_product
  end
  
  # Calculate totals based on materials, processes, and extras
  def calculate_totals
    # Calculate materials cost
    materials_cost = materials.sum { |m| m["subtotal_price"].to_f }
    
    # Calculate processes cost
    processes_cost = processes.sum { |p| p["subtotal_price"].to_f }
    
    # Calculate extras cost
    extras_cost = extras.sum { |e| e["subtotal_price"].to_f }
    
    # Calculate subtotal based on whether extras should be included
    include_extras_in_subtotal = data["include_extras_in_subtotal"] != false
    subtotal = materials_cost + processes_cost + (include_extras_in_subtotal ? extras_cost : 0)
    
    # Get waste percentage (from product or user default)
    waste_pct = pricing["waste_percentage"] || pricing[:waste_percentage] || user.waste_percentage
    
    # Calculate waste value
    waste_value = subtotal * (waste_pct / 100.0)
    
    # Calculate price per piece before margin
    quantity = general_info["quantity"].to_i
    quantity = 1 if quantity <= 0
    price_per_piece_before_margin = (subtotal + waste_value) / quantity
    
    # Calculate total before margin (subtotal + waste)
    total_before_margin = subtotal + waste_value
    
    # Get margin percentage - use manually set if provided, otherwise calculate from price_margins
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
  
  # Helper method to add a new material
  def add_material(material_id, options = {})
    # Create a new material from the template
    material = self.class.material_template.merge({
      "material_id" => material_id
    }).merge(options)
    
    # Add it to the materials array
    new_materials = materials.dup
    new_materials << material
    self.materials = new_materials
    
    # Calculate and update its values
    calculate_material_cost(material)
    
    # Return the updated product
    self
  end
  
  # Helper method to add a new process
  def add_process(process_id, options = {})
    # Create a new process from the template
    process = self.class.process_template.merge({
      "process_id" => process_id
    }).merge(options)
    
    # Add it to the processes array
    new_processes = processes.dup
    new_processes << process
    self.processes = new_processes
    
    # Calculate and update its values
    calculate_process_cost(process)
    
    # Return the updated product
    self
  end
  
  # Helper method to add a new extra
  def add_extra(extra_id, options = {})
    # Create a new extra from the template
    extra = self.class.extra_template.merge({
      "extra_id" => extra_id
    }).merge(options)
    
    # Add it to the extras array
    new_extras = extras.dup
    new_extras << extra
    self.extras = new_extras
    
    # Calculate and update its values
    calculate_extra_cost(extra)
    
    # Return the updated product
    self
  end
  
  # Helper method to update a material
  def update_material(material_id, options = {})
    # Find the material index
    material_index = materials.index { |m| m["material_id"] == material_id }
    return self unless material_index
    
    # Update the material with the new options
    new_materials = materials.dup
    new_materials[material_index] = new_materials[material_index].merge(options)
    self.materials = new_materials
    
    # Calculate and update its values
    calculate_material_cost(new_materials[material_index])
    
    # Return the updated product
    self
  end
  
  # Helper method to update a process
  def update_process(process_id, options = {})
    # Find the process index
    process_index = processes.index { |p| p["process_id"] == process_id }
    return self unless process_index
    
    # Update the process with the new options
    new_processes = processes.dup
    new_processes[process_index] = new_processes[process_index].merge(options)
    self.processes = new_processes
    
    # Calculate and update its values
    calculate_process_cost(new_processes[process_index])
    
    # Return the updated product
    self
  end
  
  # Helper method to update an extra
  def update_extra(extra_id, options = {})
    # Find the extra index
    extra_index = extras.index { |e| e["extra_id"] == extra_id }
    return self unless extra_index
    
    # Update the extra with the new options
    new_extras = extras.dup
    new_extras[extra_index] = new_extras[extra_index].merge(options)
    self.extras = new_extras
    
    # Calculate and update its values
    calculate_extra_cost(new_extras[extra_index])
    
    # Return the updated product
    self
  end
  
  # Helper method to remove a material
  def remove_material(material_id)
    new_materials = materials.reject { |m| m["material_id"] == material_id }
    self.materials = new_materials
    self
  end
  
  # Helper method to remove a process
  def remove_process(process_id)
    new_processes = processes.reject { |p| p["process_id"] == process_id }
    self.processes = new_processes
    self
  end
  
  # Helper method to remove an extra
  def remove_extra(extra_id)
    new_extras = extras.reject { |e| e["extra_id"] == extra_id }
    self.extras = new_extras
    self
  end
  
  def calculate_margin_percentage(total_before_margin)
    # Find the appropriate price margin based on the total before margin
    price_margin = user.price_margins.where("min_price <= ? AND max_price >= ?", total_before_margin, total_before_margin).first
    price_margin&.margin_percentage || 0
  end
  
  private
  
  # Calculate cost for a material based on its properties and quantity
  def calculate_material_cost(material)
    return 0 unless material["material_id"]
    
    material_record = user.materials.find_by(id: material["material_id"])
    return 0 unless material_record
    
    # Get values or defaults
    material_price = material_record.price || 0
    material_width = material_record.ancho || 0
    material_length = material_record.largo || 0
    material_unit = material_record.unit
    
    width = material["width"].to_f || 0
    length = material["length"].to_f || 0
    quantity = material["quantity"].to_f || 0
    pieces_per_material = material["pieces_per_material"].to_f || 0
    
    # Calculate totals based on unit type
    total_sheets = 0
    total_square_meters = 0
    subtotal_price = 0
    
    if material_unit && material_unit.name.downcase.include?("m2")
      # For materials measured in square meters
      total_square_meters = (width * length * quantity) / 10000.0  # cm² to m²
      subtotal_price = total_square_meters * material_price
    elsif pieces_per_material > 0
      # For materials with piece counts
      total_sheets = (quantity / pieces_per_material).ceil
      subtotal_price = total_sheets * material_price
    else
      # Default calculation
      subtotal_price = quantity * material_price
    end
    
    # Update the material with calculated values
    updated_material = material.merge(
      "description" => material_record.description,
      "price" => material_price,
      "unit" => material_unit ? {
        "id" => material_unit.id,
        "name" => material_unit.name,
        "abbreviation" => material_unit.abbreviation
      } : nil,
      "width" => width,
      "length" => length,
      "pieces_per_material" => pieces_per_material,
      "total_sheets" => total_sheets,
      "total_square_meters" => total_square_meters,
      "subtotal_price" => subtotal_price
    )
    
    # Replace the material in the materials array
    material_index = materials.index { |m| m["material_id"] == material["material_id"] }
    if material_index
      new_materials = materials.dup
      new_materials[material_index] = updated_material
      self.materials = new_materials
    end
    
    return subtotal_price
  end
  
  # Calculate cost for a process based on its properties
  def calculate_process_cost(process)
    return 0 unless process["process_id"]
    
    process_record = user.manufacturing_processes.find_by(id: process["process_id"])
    return 0 unless process_record
    
    # Get values or defaults
    process_price = process_record.cost || 0
    process_unit = process_record.unit
    quantity = process["quantity"].to_f || 0
    
    # Calculate subtotal
    subtotal_price = process_price * quantity
    
    # Update the process with calculated values
    updated_process = process.merge(
      "description" => process_record.name,
      "price" => process_price,
      "unit" => process_unit ? {
        "id" => process_unit.id,
        "name" => process_unit.name,
        "abbreviation" => process_unit.abbreviation
      } : nil,
      "subtotal_price" => subtotal_price
    )
    
    # Replace the process in the processes array
    process_index = processes.index { |p| p["process_id"] == process["process_id"] }
    if process_index
      new_processes = processes.dup
      new_processes[process_index] = updated_process
      self.processes = new_processes
    end
    
    return subtotal_price
  end
  
  # Calculate cost for an extra based on its properties
  def calculate_extra_cost(extra)
    return 0 unless extra["extra_id"]
    
    extra_record = user.extras.find_by(id: extra["extra_id"])
    return 0 unless extra_record
    
    # Get values or defaults
    extra_price = extra_record.cost || 0
    quantity = extra["quantity"].to_f || 0
    
    # Calculate subtotal
    subtotal_price = extra_price * quantity
    
    # Update the extra with calculated values
    updated_extra = extra.merge(
      "description" => extra_record.name,
      "price" => extra_price,
      "quantity" => quantity,
      "subtotal_price" => subtotal_price
    )
    
    # Replace the extra in the extras array
    extra_index = extras.index { |e| e["extra_id"] == extra["extra_id"] }
    if extra_index
      new_extras = extras.dup
      new_extras[extra_index] = updated_extra
      self.extras = new_extras
    end
    
    return subtotal_price
  end
end 