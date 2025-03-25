class Api::V1::ProductsController < ApplicationController
  before_action :set_product, only: [:show, :update, :extras, :update_extras, :update_extras_comments, :update_processes, :update_processes_comments, :update_materials, :update_materials_comments, :update_pricing, :update_selected_material]
  skip_before_action :verify_authenticity_token, only: [:create, :update, :update_extras, :update_extras_comments, :update_processes, :update_processes_comments, :update_materials, :update_materials_comments, :update_pricing, :update_selected_material]

  # GET /api/v1/products/:id
  def show
    render json: @product
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

  # GET /api/v1/products/:id/extras
  def extras
    render json: @product.extras
  end

  # PUT /api/v1/products/:id/extras
  def update_extras
    @product.data["extras"] = extras_params
    @product.calculate_totals
    
    if @product.save
      render json: @product.extras
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/extras
  def available_extras
    @extras = current_user.extras.order(:name)
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

  # PUT /api/v1/products/:id/update_extras_comments
  def update_extras_comments
    @product.data["extras_comments"] = params[:extras_comments]
    
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
    params.require(:extras)
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
      price: material.price || 0,
      resistance: material.resistance,
      unit: material.unit ? material.unit.name : 'unidad',
      unit_object: material.unit ? {
        id: material.unit.id,
        name: material.unit.name,
        abbreviation: material.unit.try(:abbreviation)
      } : nil
    }
  end

  # Helper method to ensure pricing data is properly calculated
  def ensure_pricing_calculated(product)
    return if product.data.blank? || product.data["pricing"].blank?
    
    # Calculate costs from materials, processes, and extras
    materials_cost = calculate_materials_cost(product.data["materials"] || [])
    processes_cost = calculate_processes_cost(product.data["processes"] || [])
    extras_cost = calculate_extras_cost(product.data["extras"] || [])
    
    # Update pricing data
    pricing = product.data["pricing"]
    pricing["materials_cost"] = materials_cost
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