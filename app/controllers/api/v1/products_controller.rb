class Api::V1::ProductsController < ApplicationController
  before_action :set_product, only: [
    :show, :update,
    :indirect_costs, :update_indirect_costs, :update_indirect_costs_comments,
    :update_processes, :update_processes_comments,
    :update_materials, :update_materials_comments,
    :update_pricing, :update_selected_material,
    :update_include_indirect_costs_in_subtotal
  ]
  skip_before_action :verify_authenticity_token, only: [
    :create, :update,
    :update_indirect_costs, :update_indirect_costs_comments,
    :update_processes, :update_processes_comments,
    :update_materials, :update_materials_comments,
    :update_pricing, :update_selected_material,
    :update_include_indirect_costs_in_subtotal
  ]

  # GET /api/v1/products/:id
  def show
    render json: {
      id: @product.id,
      description: @product.description,
      data: @product.data
    }
  end

  # POST /api/v1/products
  def create
    @product = current_user.products.build(product_params)
    
    # Just save the product with all data from the form as-is
    # No recalculation needed since frontend has all the values
    
    if @product.save
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/products/:id
  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/products/:id/indirect_costs
  def indirect_costs
    render json: @product.indirect_costs
  end

  # PUT /api/v1/products/:id/update_indirect_costs
  def update_indirect_costs
    extras_array = extras_params
    @product.data["indirect_costs"] = extras_array
    @product.data["extras"] = extras_array
    @product.calculate_totals
    
    if @product.save
      render json: @product.indirect_costs
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/indirect_costs
  def available_indirect_costs
    @extras = current_user.indirect_costs.order(:name)
    render json: @extras.map { |e| extra_json(e) }
  end

  # GET /api/v1/manufacturing_processes
  def available_manufacturing_processes
    @manufacturing_processes = current_user.manufacturing_processes
    render json: @manufacturing_processes.map { |p| process_json(p) }, status: :ok
  end

  def available_materials
    @materials = current_user.materials
    render json: @materials.map { |m| material_json(m) }, status: :ok
  end

  def available_units
    @units = Unit.all.order(:name)
    render json: @units.map { |u| unit_json(u) }, status: :ok
  end

  # PUT /api/v1/products/:id/update_indirect_costs_comments
  def update_indirect_costs_comments
    comments = params[:indirect_costs_comments] || params[:extras_comments]
    @product.data["indirect_costs_comments"] = comments
    @product.data["extras_comments"] = comments
    
    if @product.save
      render json: { success: true }
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/products/:id/update_processes
  def update_processes
    @product.data["processes"] = processes_params
    @product.calculate_totals
    
    if @product.save
      render json: @product.data["processes"]
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/products/:id/update_processes_comments
  def update_processes_comments
    @product.data["processes_comments"] = params[:processes_comments]
    
    if @product.save
      render json: { success: true }
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/products/:id/update_materials
  def update_materials
    @product.data["materials"] = materials_params
    @product.calculate_totals
    
    if @product.save
      render json: @product.data["materials"]
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/products/:id/update_materials_comments
  def update_materials_comments
    @product.data["materials_comments"] = params[:materials_comments]
    
    if @product.save
      render json: { success: true }
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # PUT /api/v1/products/:id/update_pricing
  def update_pricing
    @product.data["pricing"] = pricing_params
    
    if @product.save
      render json: @product
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/products/:id/update_selected_material
  def update_selected_material
    @product.data["selected_material_id"] = params[:selected_material_id]
    
    if @product.save
      render json: { success: true }
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/products/:id/update_include_indirect_costs_in_subtotal
  def update_include_indirect_costs_in_subtotal
    flag = params[:include_indirect_costs_in_subtotal]
    flag = params[:include_extras_in_subtotal] if flag.nil?
    @product.data["include_indirect_costs_in_subtotal"] = flag
    @product.data["include_extras_in_subtotal"] = flag
    
    if @product.save
      render json: { success: true }
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :description,
      data: {}
    )
  end

  def extras_params
    params.require(:indirect_costs) if params.key?(:indirect_costs)
    params.require(:extras) if params.key?(:extras)
    params[:indirect_costs] || params[:extras]
  end

  def processes_params
    params.require(:processes)
  end

  def materials_params
    params.require(:materials)
  end

  def pricing_params
    params.require(:pricing)
  end

  def extra_json(extra)
    {
      id: extra.id,
      name: extra.name,
      description: extra.description,
      unit_price: extra.cost,
      unit: extra.unit ? extra.unit.name : 'unit',
      unit_object: extra.unit ? {
        id: extra.unit.id,
        name: extra.unit.name,
        abbreviation: extra.unit.abbreviation
      } : nil
    }
  end

  def process_json(process)
    {
      id: process.id,
      description: process.name || process.description,
      unit: process.unit ? process.unit.name : 'unidad',
      price: process.cost || 0,
      side: process.side || 'front',
      side_label: process.side_label,
      unit_object: process.unit ? {
        id: process.unit.id,
        name: process.unit.name,
        abbreviation: process.unit.try(:abbreviation)
      } : nil
    }
  end

  def material_json(material)
    {
      id: material.id,
      description: material.description,
      client_description: material.client_description,
      ancho: material.ancho,
      largo: material.largo,
      cost: material.cost || 0,
      weight: material.weight || 0,
      resistance: material.resistance,
      unit: material.unit ? material.unit.name : 'unidad',
      unit_object: material.unit ? {
        id: material.unit.id,
        name: material.unit.name,
        abbreviation: material.unit.try(:abbreviation)
      } : nil
    }
  end

  def unit_json(unit)
    {
      id: unit.id,
      name: unit.name,
      abbreviation: unit.abbreviation
    }
  end

  # Helper method to ensure pricing data is properly calculated
  def ensure_pricing_calculated(product)
    return if product.data.blank? || product.data["pricing"].blank?
    
    # Calculate costs from materials, processes, and extras
    materials_cost = calculate_materials_cost(product.data["materials"] || [])
    material_processes_cost = calculate_material_processes_cost(product)
    global_processes_cost = calculate_global_processes_cost(product)
    processes_cost = material_processes_cost + global_processes_cost
    extras_cost = calculate_extras_cost(product.data["extras"] || [])
    
    # Update pricing data
    pricing = product.data["pricing"]
    pricing["materials_cost"] = materials_cost
    pricing["material_processes_cost"] = material_processes_cost
    pricing["global_processes_cost"] = global_processes_cost
    pricing["processes_cost"] = processes_cost
    pricing["extras_cost"] = extras_cost
    
    # Calculate subtotal
    subtotal = materials_cost + processes_cost + extras_cost
    pricing["subtotal"] = subtotal
    
    # Calculate waste value
    waste_percentage = pricing["waste_percentage"].to_f
    waste_value = subtotal * (waste_percentage / 100)
    pricing["waste_value"] = waste_value
    
    # Calculate price per piece before margin
    quantity = (product.data["general_info"] && product.data["general_info"]["quantity"]) || product.data["quantity"] || 1
    quantity = [quantity.to_i, 1].max # Ensure quantity is at least 1
    pricing["price_per_piece_before_margin"] = (subtotal + waste_value) / quantity
    
    # Calculate margin
    margin_percentage = pricing["margin_percentage"].to_f
    margin_value = (subtotal + waste_value) * (margin_percentage / 100)
    pricing["margin_value"] = margin_value
    
    # Calculate total price
    pricing["total_price"] = subtotal + waste_value + margin_value
    
    # Calculate final price per piece
    pricing["final_price_per_piece"] = pricing["total_price"] / quantity
  end
  
  def calculate_materials_cost(materials)
    materials.sum { |m| (m["totalPrice"].to_f rescue 0) }
  end
  
  def calculate_material_processes_cost(product)
    total = 0
    
    # Calculate processes from materials
    if product.data["materials"].present?
      product.data["materials"].each do |material|
        if material["processes"].present?
          material["processes"].each do |process|
            total += (process["price"].to_f rescue 0) * (process["veces"].to_f rescue 1)
          end
        end
      end
    end
    
    total
  end
  
  def calculate_global_processes_cost(product)
    total = 0
    
    # Calculate global processes from data
    if product.data["global_processes"].present?
      product.data["global_processes"].each do |process|
        total += (process["price"].to_f rescue 0) * (process["veces"].to_f rescue 1)
      end
    end
    
    # Also check for processes in the old format (processes without materialId)
    if product.data["processes"].present?
      product.data["processes"].each do |process|
        # Only count processes that don't have a materialId (global processes)
        unless process["materialId"].present?
          total += (process["price"].to_f rescue 0) * (process["veces"].to_f rescue 1)
        end
      end
    end
    
    total
  end
  
  def calculate_processes_cost(processes)
    processes.sum { |p| (p["price"].to_f rescue 0) }
  end
  
  def calculate_extras_cost(extras)
    extras.sum do |e|
      unit_price = (e["unit_price"].to_f rescue 0)
      quantity = (e["quantity"].to_i rescue 0)
      unit_price * quantity
    end
  end
end 