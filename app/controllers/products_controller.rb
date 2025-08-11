class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :edit_v2, :update, :destroy, :duplicate]
  before_action :no_cache, only: [:index, :show, :new, :edit, :edit_v2]

  def index
    @products = current_user.products.order(created_at: :desc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      if adapter.include?("sqlite")
        @products = @products.where("description LIKE ?", query)
      else
        @products = @products.where("description ILIKE ?", query)
      end
    end
    @products = @products.page(params[:page]).per(10)
  end

  def show
    # Calculate extras costs before showing the view
    @product.extras.each do |extra|
      @product.calculate_extra_cost(extra)
    end
    @product.save
  end

  def new
    @product = current_user.products.build
    initialize_product_data(@product)
  end

  def new_v2
    # This action will render the new V2 form
  end

  def edit_v2
    # This action will render the edit V2 form
  end

  def edit
  end

  def create
    @product = current_user.products.build(product_params)
    initialize_product_data(@product)

    respond_to do |format|
      if @product.save
        @product.calculate_totals.save
        format.html { redirect_to products_path, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @product.update(product_params)
        @product.calculate_totals.save
        format.html { redirect_to products_path }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def duplicate
    new_product = @product.deep_clone
    initialize_product_data(new_product)
    
    respond_to do |format|
      if new_product.save
        format.html { redirect_to edit_v2_product_path(new_product) }
        format.json { render :show, status: :created, location: new_product }
      else
        format.html { redirect_to products_path, alert: 'Failed to duplicate product.' }
        format.json { render json: new_product.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    begin
      if @product.quote_products.any?
        quotes = @product.quotes.pluck(:quote_number).join(", ")
        redirect_to products_path, 
          alert: "No se puede eliminar el producto porque está siendo utilizado en las siguientes cotizaciones: #{quotes}"
      else
        @product.destroy
        redirect_to products_path
      end
    rescue => e
      redirect_to products_path, alert: 'Error al intentar eliminar el producto.'
    end
  end
  
  # API endpoints for Vue component
  def materials_list
    @materials = current_user.materials.includes(:unit).order(:description)
    no_cache
    render json: @materials.map { |m| material_json(m) }
  end
  
  def processes_list
    @processes = current_user.manufacturing_processes.includes(:unit).order(:name)
    render json: @processes.map { |p| process_json(p) }
  end
  
  def extras_list
    respond_to do |format|
      begin
     @extras = current_user.indirect_costs.order(:name)
        extras_data = @extras.map { |e| extra_json(e) }
        
        # Log for debugging
        Rails.logger.debug "Extras list requested. Found #{@extras.count} extras."
        Rails.logger.debug "Extras data: #{extras_data.inspect}"
        
        format.json { render json: extras_data }
        format.html { redirect_to products_path }
      rescue => e
        Rails.logger.error "Error in extras_list: #{e.message}"
        format.json { render json: { error: e.message }, status: :internal_server_error }
        format.html { redirect_to products_path, alert: "Error loading extras: #{e.message}" }
      end
    end
  end

  def general_info
    render json: {
      general_info: @product.general_info,
      config: {
        waste_percentage: current_user.get_config(AppConfig::WASTE_PERCENTAGE) || 5,
        width_margin: current_user.get_config(AppConfig::WIDTH_MARGIN) || 0,
        length_margin: current_user.get_config(AppConfig::LENGTH_MARGIN) || 0
      }
    }
  end
  
  def pricing
    @product = Product.find(params[:id])
  end

  def modal_test
    # This action is just for testing modals
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_params
    # Allow the nested JSON data structure
    permitted_params = params.require(:product).permit(
      :description,
      data: {
        general_info: [
          :width, :length, :inner_measurements, :quantity,
          :comments
        ],
        materials: [],
        processes: [],
        extras: [],
        pricing: [
          :materials_cost, :processes_cost, :extras_cost, :subtotal,
          :waste_percentage, :waste_value, :price_per_piece_before_margin,
          :margin_percentage, :margin_value, :total_price, :final_price_per_piece
        ]
      }
    )
    
    # If the data parameter is present but empty (common with nested forms), 
    # initialize it with the default structure
    if permitted_params[:data].blank?
      permitted_params[:data] = Product.default_data
    end
    
    permitted_params
  end
  
  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  # Helpers to format JSON for API responses
  def material_json(material)
    {
      id: material.id,
      description: material.description,
      client_description: material.client_description,
      cost: material.cost,
      resistance: material.resistance,
      ancho: material.ancho,
      largo: material.largo,
      weight: material.weight,
      unit: material.unit ? {
        id: material.unit.id,
        name: material.unit.name,
        abbreviation: material.unit.abbreviation
      } : nil
    }
  end
  
  def process_json(process)
    {
      id: process.id,
      name: process.name,
      description: process.description,
      cost: process.cost,
      unit: process.unit ? {
        id: process.unit.id,
        name: process.unit.name,
        abbreviation: process.unit.abbreviation
      } : nil
    }
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

  # Helper method to initialize product data with default values
  def initialize_product_data(product)
    # Set default waste percentage from user config
    if product.pricing["waste_percentage"].nil?
      waste_pct = current_user.get_config(AppConfig::WASTE_PERCENTAGE) || 5.0
      product.pricing = product.pricing.merge("waste_percentage" => waste_pct)
    end
    
    # Ensure general_info is properly initialized
    if product.general_info["quantity"].nil? || product.general_info["quantity"] < 1
      product.general_info = product.general_info.merge("quantity" => 1)
    end
    
    # Set default width and length to 1
    if product.general_info["width"].nil? || product.general_info["width"] <= 0
      product.general_info = product.general_info.merge("width" => 1)
    end
    
    if product.general_info["length"].nil? || product.general_info["length"] <= 0
      product.general_info = product.general_info.merge("length" => 1)
    end
    
    product
  end
end 