class QuotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote, only: [:show, :edit, :update, :destroy, :add_product, :remove_product, :update_product_quantity, :pdf, :modern_pdf]
  
  # Use the Vue-specific layout for new and edit pages
  layout 'vue_application', only: [:new, :edit]
  
  def index
    @quotes = current_user.quotes.order(created_at: :desc).limit(10)
  end
  
  def show
    @products = @quote.quote_products.includes(:product)
  end
  
  def new
    @quote = current_user.quotes.new
    @products = current_user.products
  end
  
  def create
    begin
      Rails.logger.info "[QuotesController#create] params[:quote_data] class: #{params[:quote_data].class}"
      quote_data = params[:quote_data]
      if quote_data.is_a?(String)
        quote_data = JSON.parse(quote_data)
      end
      Rails.logger.info "[QuotesController#create] quote_data: #{quote_data.inspect}"
      
      @quote = current_user.quotes.new(
        project_name: quote_data['project_name'],
        customer_name: quote_data['customer_name'],
        organization: quote_data['organization'],
        email: quote_data['email'],
        telephone: quote_data['telephone'],
        comments: quote_data['comments'],
        data: quote_data['data'] || {}
      )
      
      # Validate all required fields in order
      @quote.valid? # Populate errors
      ordered_errors = []
      ordered_errors << "El nombre del proyecto es requerido" if @quote.errors[:project_name].present?
      ordered_errors << "El nombre del cliente es requerido" if @quote.errors[:customer_name].present?
      ordered_errors << "La organización es requerida" if @quote.errors[:organization].present?
      ordered_errors << "El correo electrónico es requerido" if @quote.errors[:email].present?
      if quote_data['selected_products'].blank?
        ordered_errors << "Debe agregar al menos un producto a la cotización"
      end
      if ordered_errors.any?
        @products = current_user.products
        respond_to do |format|
          format.html { render :new }
          format.json { render json: { errors: ordered_errors }, status: :unprocessable_entity }
        end
        return
      end
      
      if @quote.save
        # Add selected products if any
        if quote_data['selected_products'].present?
          quote_data['selected_products'].each do |product_data|
            @quote.quote_products.create(
              product_id: product_data['product_id'],
              quantity: product_data['quantity']
            )
          end
        end
        
        respond_to do |format|
          format.html { redirect_to quotes_path }
          format.json { render json: { success: true, redirect_url: quotes_path } }
        end
      else
        Rails.logger.info "[QuotesController#create] Validation errors: #{@quote.errors.map(&:message)}"
        @products = current_user.products
        respond_to do |format|
          format.html { render :new }
          format.json { render json: { errors: @quote.errors.map(&:message) }, status: :unprocessable_entity }
        end
      end
    rescue => e
      Rails.logger.error "[QuotesController#create] Exception: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}" 
      @products = current_user.products
      respond_to do |format|
        format.html do
          flash.now[:alert] = "Error al procesar los datos: #{e.message}"
          render :new
        end
        format.json { render json: { error: "Error al procesar los datos: #{e.message}" }, status: :bad_request }
      end
    end
  end
  
  def edit
    @products = current_user.products
    # Get list of products already in the quote
    @quote_product_ids = @quote.products.pluck(:id)
  end
  
  def update
    begin
      Rails.logger.info "[QuotesController#update] params[:quote_data] class: #{params[:quote_data].class}"
      quote_data = params[:quote_data]
      if quote_data.is_a?(String)
        quote_data = JSON.parse(quote_data)
      end
      Rails.logger.info "[QuotesController#update] quote_data: #{quote_data.inspect}"
      
      @quote.assign_attributes(
        project_name: quote_data['project_name'],
        customer_name: quote_data['customer_name'],
        organization: quote_data['organization'],
        email: quote_data['email'],
        telephone: quote_data['telephone'],
        comments: quote_data['comments'],
        data: quote_data['data'] || {}
      )
      
      # Validate all required fields in order (update)
      @quote.valid?
      ordered_errors = []
      ordered_errors << "El nombre del proyecto es requerido" if @quote.errors[:project_name].present?
      ordered_errors << "El nombre del cliente es requerido" if @quote.errors[:customer_name].present?
      ordered_errors << "La organización es requerida" if @quote.errors[:organization].present?
      ordered_errors << "El correo electrónico es requerido" if @quote.errors[:email].present?
      if quote_data['selected_products'].blank?
        ordered_errors << "Debe agregar al menos un producto a la cotización"
      end
      if ordered_errors.any?
        @products = current_user.products
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: { errors: ordered_errors }, status: :unprocessable_entity }
        end
        return
      end
      
      if @quote.save
        # Remove existing products and add the new selection
        @quote.quote_products.destroy_all
        
        if quote_data['selected_products'].present?
          quote_data['selected_products'].each do |product_data|
            @quote.quote_products.create(
              product_id: product_data['product_id'],
              quantity: product_data['quantity']
            )
          end
        end
        
        respond_to do |format|
          format.html { redirect_to quotes_path, notice: "Cotización actualizada exitosamente." }
          format.json { render json: { success: true, redirect_url: quotes_path } }
        end
      else
        Rails.logger.info "[QuotesController#update] Validation errors: #{@quote.errors.map(&:message)}"
        @products = current_user.products
        respond_to do |format|
          format.html { render :edit }
          format.json { render json: { errors: @quote.errors.map(&:message) }, status: :unprocessable_entity }
        end
      end
    rescue => e
      Rails.logger.error "[QuotesController#update] Exception: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}" 
      @products = current_user.products
      respond_to do |format|
        format.html do
          flash.now[:alert] = "Error al procesar los datos: #{e.message}"
          render :edit
        end
        format.json { render json: { error: "Error al procesar los datos: #{e.message}" }, status: :bad_request }
      end
    end
  end
  
  def destroy
    @quote.destroy
    redirect_to quotes_path
  end
  
  # Product management
  def add_product
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    
    quantity = 1 if quantity <= 0
    
    success = @quote.add_product(product_id, quantity)
    
    respond_to do |format|
      if success
        format.html { redirect_back fallback_location: edit_quote_path(@quote), notice: 'Product added to quote.' }
        format.json { render json: { success: true, message: 'Product added to quote.' } }
      else
        format.html { redirect_back fallback_location: edit_quote_path(@quote), alert: 'Error adding product to quote.' }
        format.json { render json: { success: false, message: 'Error adding product to quote.' } }
      end
    end
  end
  
  def remove_product
    product_id = params[:product_id]
    success = @quote.remove_product(product_id)
    
    respond_to do |format|
      if success
        format.html { redirect_back fallback_location: edit_quote_path(@quote), notice: 'Product removed from quote.' }
        format.json { render json: { success: true, message: 'Product removed from quote.' } }
      else
        format.html { redirect_back fallback_location: edit_quote_path(@quote), alert: 'Error removing product from quote.' }
        format.json { render json: { success: false, message: 'Error removing product from quote.' } }
      end
    end
  end
  
  def update_product_quantity
    product_id = params[:product_id]
    quantity = params[:quantity].to_i
    
    success = @quote.update_product_quantity(product_id, quantity)
    
    respond_to do |format|
      if success
        format.html { redirect_back fallback_location: edit_quote_path(@quote), notice: 'Product quantity updated.' }
        format.json { render json: { success: true, message: 'Product quantity updated.' } }
      else
        format.html { redirect_back fallback_location: edit_quote_path(@quote), alert: 'Error updating product quantity.' }
        format.json { render json: { success: false, message: 'Error updating product quantity.' } }
      end
    end
  end
  
  # Customer search via Pipedrive or local database
  def search_customer
    begin
      query = params[:query]
      Rails.logger.info "[search_customer] Query: #{query.inspect}"
      
      # Return early if query is too short
      if query.blank? || query.length < 3
        Rails.logger.info "[search_customer] Query too short"
        render json: { error: "Search query must be at least 3 characters." }, status: :bad_request
        return
      end
      
      # Get API key from database
      api_key = AppConfig.get_pipedrive_api_key(current_user)
      Rails.logger.info "[search_customer] API key present: #{api_key.present?}"
      customers = []
      
      if api_key.present?
        # Search in Pipedrive if API key is configured
        begin
          url = URI("https://api.pipedrive.com/v1/persons/search?term=#{CGI.escape(query)}&api_token=#{api_key}")
          http = Net::HTTP.new(url.host, url.port)
          http.use_ssl = (url.scheme == 'https')
          http.verify_mode = OpenSSL::SSL::VERIFY_PEER
          request = Net::HTTP::Get.new(url)
          request["Accept"] = "application/json"
          response = http.request(request)
          Rails.logger.info "[search_customer] Pipedrive response code: #{response.code}"
          if response.code == '200'
            data = JSON.parse(response.body)
            if data['data'] && data['data']['items']
              data['data']['items'].each do |item|
                person = item['item']
                email = if person['email']
                         person['email'].is_a?(Array) ? person['email'].first['value'] : person['email']
                       elsif person['emails']
                         person['emails'].is_a?(Array) ? person['emails'].first : person['emails']
                       end
                phone = if person['phone']
                         person['phone'].is_a?(Array) ? person['phone'].first['value'] : person['phone']
                       elsif person['phones']
                         person['phones'].is_a?(Array) ? person['phones'].first : person['phones']
                       end
                customers << {
                  id: person['id'],
                  name: person['name'],
                  email: email,
                  phone: phone,
                  org_name: person.dig('organization', 'name')
                }
              end
            end
          else
            Rails.logger.error("[search_customer] Pipedrive API error: #{response.code}")
          end
        rescue => e
          Rails.logger.error("[search_customer] Pipedrive API error: #{e.message}")
        end
      end
      
      # If no customers found from Pipedrive or no API key, search in local database
      if customers.empty?
        Rails.logger.info "[search_customer] Searching local customers for query: #{query.inspect}"
        customers = current_user.customers
          .where("name LIKE ? OR email LIKE ? OR company LIKE ?", "%#{query}%", "%#{query}%", "%#{query}%")
          .limit(10)
          .map do |customer|
            {
              id: customer.id,
              name: customer.name,
              email: customer.email,
              phone: customer.phone,
              org_name: customer.company
            }
          end
        Rails.logger.info "[search_customer] Local customers found: #{customers.size}"
      end
      
      render json: { customers: customers }, status: :ok
    rescue => e
      Rails.logger.error "[search_customer] Unexpected error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      render json: { customers: [] }, status: :ok
    end
  end
  
  # PDF Generation
  def pdf
    pdf_content = generate_pdf_for_quote(@quote)
    filename = "#{@quote.quote_number}.pdf"
    
    respond_to do |format|
      format.pdf do
        send_data pdf_content, 
                  filename: filename, 
                  type: 'application/pdf', 
                  disposition: 'inline'
      end
    end
  end
  
  def modern_pdf
    pdf_content = generate_modern_pdf_for_quote(@quote)
    filename = "#{@quote.quote_number}.pdf"
    
    respond_to do |format|
      format.pdf do
        send_data pdf_content, 
                  filename: filename, 
                  type: 'application/pdf', 
                  disposition: 'inline'
      end
    end
  end
  
  def duplicate
    @original_quote = current_user.quotes.find(params[:id])
    
    # Create a new quote with the same attributes
    @quote = current_user.quotes.new(
      project_name: "#{@original_quote.project_name} (Copia)",
      customer_name: @original_quote.customer_name,
      organization: @original_quote.organization,
      email: @original_quote.email,
      telephone: @original_quote.telephone,
      comments: @original_quote.comments,
      data: @original_quote.data
    )
    
    if @quote.save
      # Copy all quote products
      @original_quote.quote_products.each do |quote_product|
        @quote.quote_products.create(
          product_id: quote_product.product_id,
          quantity: quote_product.quantity
        )
      end
      
      redirect_to edit_quote_path(@quote), notice: "Cotización duplicada exitosamente."
    else
      redirect_to quotes_path, alert: "Error al duplicar la cotización."
    end
  end
  
  def send_email
    @quote = current_user.quotes.includes(:user, :quote_products => [:product]).find(params[:id])
    
    begin
      pdf_content = generate_modern_pdf_for_quote(@quote)
      
      QuoteMailer.with(
        quote: @quote,
        user: current_user,
        message: "Adjuntamos la cotización solicitada. Si tienes alguna duda, por favor responde a este correo.",
        pdf_content: pdf_content
      ).send_quote.deliver_now
      
      respond_to do |format|
        format.html { redirect_to quotes_path, notice: 'La cotización ha sido enviada por correo.' }
        format.json { render json: { message: 'Email sent successfully' }, status: :ok }
      end
    rescue => e
      Rails.logger.error "Error sending email: #{e.message}"
      respond_to do |format|
        format.html { redirect_to quotes_path, alert: 'Error al enviar el correo. Por favor intente nuevamente.' }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end
  
  private
  
  def generate_pdf_for_quote(quote)
    # Ensure we have all the necessary associations loaded
    quote = Quote.includes(:user, :quote_products => [:product]).find(quote.id) unless quote.quote_products.loaded?
    pdf_generator = QuotePdfGenerator.new(quote)
    pdf_generator.generate
  end
  
  def generate_modern_pdf_for_quote(quote)
    quote = Quote.includes(:user, :quote_products => [:product]).find(quote.id) unless quote.quote_products.loaded?
    pdf_generator = QuotePdfGeneratorModern.new(quote)
    pdf_generator.generate
  end
  
  def set_quote
    @quote = current_user.quotes.includes(:user, quote_products: [:product]).find(params[:id])
  end
  
  def quote_params
    params.require(:quote).permit(:project_name, :customer_name, :organization, :email, :telephone, :comments)
  end
  
  def quote_params_with_json(json_params)
    # Convert JSON parameters to the format Rails expects
    return {} if json_params.blank?
    
    # Convert string keys to symbols, but only for top-level keys that match our permitted parameters
    {
      project_name: json_params['project_name'],
      customer_name: json_params['customer_name'],
      organization: json_params['organization'],
      email: json_params['email'],
      telephone: json_params['telephone'],
      comments: json_params['comments']
    }.compact
  end
end 