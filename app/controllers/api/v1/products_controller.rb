class Api::V1::ProductsController < ApplicationController
  before_action :set_product, only: [:show, :update, :extras, :update_extras, :update_extras_comments, :update_processes, :update_processes_comments, :update_materials, :update_materials_comments, :update_pricing]
  skip_before_action :verify_authenticity_token, only: [:create, :update, :update_extras, :update_extras_comments, :update_processes, :update_processes_comments, :update_materials, :update_materials_comments, :update_pricing]

  # GET /api/v1/products/:id
  def show
    render json: @product
  end

  # POST /api/v1/products
  def create
    @product = current_user.products.build(product_params)
    
    # Initialize with default data structure
    if @product.data.blank?
      @product.data = Product.default_data
    end
    
    if @product.save
      @product.calculate_totals.save
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
      description: material.description || material.nombre,
      ancho: material.ancho,
      largo: material.largo,
      price: material.price || 0,
      unit: material.unit ? material.unit.name : 'unidad',
      unit_object: material.unit ? {
        id: material.unit.id,
        name: material.unit.name,
        abbreviation: material.unit.try(:abbreviation)
      } : nil
    }
  end
end 