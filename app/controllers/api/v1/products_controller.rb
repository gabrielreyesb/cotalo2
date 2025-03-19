class Api::V1::ProductsController < ApplicationController
  before_action :set_product, only: [:show, :update, :extras, :update_extras]
  skip_before_action :verify_authenticity_token, only: [:create, :update, :update_extras]

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
end 