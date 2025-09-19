class Quote2sController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote, only: [:show, :edit, :update, :destroy]
  before_action :no_cache, only: [:index, :show, :new, :edit]

  def index
    @quotes = current_user.quote2s.order(created_at: :desc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      if adapter.include?("sqlite")
        @quotes = @quotes.where("description LIKE ? OR client_name LIKE ? OR client_email LIKE ?", query, query, query)
      else
        @quotes = @quotes.where("description ILIKE ? OR client_name ILIKE ? OR client_email ILIKE ?", query, query, query)
      end
    end
    @quotes = @quotes.page(params[:page]).per(10)
  end

  def show
    # Calculate totals before showing the view
    @quote.calculate_totals
    @quote.save
  end

  def new
    @quote = current_user.quote2s.build
    initialize_quote_data(@quote)
  end

  def edit
  end

  def create
    Rails.logger.info "Creating quote2 with params: #{params.inspect}"
    
    begin
      @quote = current_user.quote2s.build(quote_params)
      Rails.logger.info "Quote built: #{@quote.inspect}"
      
      initialize_quote_data(@quote)
      Rails.logger.info "Quote initialized: #{@quote.inspect}"

      respond_to do |format|
        if @quote.save
          Rails.logger.info "Quote saved successfully"
          @quote.calculate_totals.save
          format.html { redirect_to quote2s_path, notice: 'Cotización creada exitosamente.' }
          format.json { render :show, status: :created, location: @quote }
        else
          Rails.logger.error "Quote validation failed: #{@quote.errors.full_messages}"
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @quote.errors, status: :unprocessable_entity }
        end
      end
    rescue => e
      Rails.logger.error "Error creating quote2: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity, alert: "Error: #{e.message}" }
        format.json { render json: { error: e.message }, status: :internal_server_error }
      end
    end
  end

  def update
    respond_to do |format|
      if @quote.update(quote_params)
        @quote.calculate_totals.save
        format.html { redirect_to quote2s_path, notice: 'Cotización actualizada exitosamente.' }
        format.json { render :show, status: :ok, location: @quote }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @quote.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    begin
      @quote.destroy
      redirect_to quote2s_path, notice: 'Cotización eliminada exitosamente.'
    rescue => e
      redirect_to quote2s_path, alert: 'Error al intentar eliminar la cotización.'
    end
  end
  
  # API endpoints for Vue component (similar to ProductsController)
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
        
        Rails.logger.debug "Extras list requested for Quote2. Found #{@extras.count} extras."
        
        format.json { render json: extras_data }
        format.html { redirect_to quote2s_path }
      rescue => e
        Rails.logger.error "Error in extras_list for Quote2: #{e.message}"
        format.json { render json: { error: e.message }, status: :internal_server_error }
        format.html { redirect_to quote2s_path, alert: "Error loading extras: #{e.message}" }
      end
    end
  end

  def general_info
    render json: {
      general_info: @quote.general_info,
      config: {
        waste_percentage: current_user.get_config(AppConfig::WASTE_PERCENTAGE) || 5,
        width_margin: current_user.get_config(AppConfig::WIDTH_MARGIN) || 0,
        length_margin: current_user.get_config(AppConfig::LENGTH_MARGIN) || 0
      }
    }
  end

  private

  def set_quote
    @quote = current_user.quote2s.find(params[:id])
  end

  def quote_params
    # Allow the nested JSON data structure for product_data
    permitted_params = params.require(:quote2).permit(
      :client_name,
      :client_company,
      :client_email,
      :client_phone,
      :description,
      product_data: {
        general_info: [
          :width, :length, :inner_measurements, :quantity,
          :comments
        ],
        materials: [
          :id, :description, :client_description, :cost, :resistance,
          :ancho, :largo, :weight, :unit, processes: [
            :id, :price, :side, :times
          ]
        ],
        processes: [
          :id, :price, :side, :times
        ],
        extras: [
          :id, :name, :description, :cost, :quantity
        ],
        pricing: [
          :materials_cost, :material_processes_cost, :global_processes_cost,
          :processes_cost, :extras_cost, :subtotal,
          :waste_percentage, :waste_value, :price_per_piece_before_margin,
          :margin_percentage, :margin_value, :total_price, :final_price_per_piece
        ]
      }
    )
    
    # If the product_data parameter is present but empty, initialize it with the default structure
    if permitted_params[:product_data].blank?
      permitted_params[:product_data] = Quote2.default_product_data
    end
    
    permitted_params
  end
  
  def no_cache
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
  
  # Helpers to format JSON for API responses (same as ProductsController)
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

  # Helper method to initialize quote data with default values
  def initialize_quote_data(quote)
    begin
      # Set default waste percentage from user config
      if quote.pricing["waste_percentage"].nil?
        waste_pct = 5.0 # Default value instead of calling current_user.get_config
        quote.pricing = quote.pricing.merge("waste_percentage" => waste_pct)
      end
      
      # Ensure general_info is properly initialized
      if quote.general_info["quantity"].nil? || quote.general_info["quantity"] < 1
        quote.general_info = quote.general_info.merge("quantity" => 1)
      end
      
      # Set default width and length to 1
      if quote.general_info["width"].nil? || quote.general_info["width"] <= 0
        quote.general_info = quote.general_info.merge("width" => 1)
      end
      
      if quote.general_info["length"].nil? || quote.general_info["length"] <= 0
        quote.general_info = quote.general_info.merge("length" => 1)
      end
      
      quote
    rescue => e
      Rails.logger.error "Error in initialize_quote_data: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
end
