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
      quote_data = params[:quote_data] ? JSON.parse(params[:quote_data]) : {}
      
      @quote = current_user.quotes.new(
        project_name: quote_data['project_name'],
        customer_name: quote_data['customer_name'],
        organization: quote_data['organization'],
        email: quote_data['email'],
        telephone: quote_data['telephone'],
        comments: quote_data['comments'],
        data: quote_data['data'] || {}
      )
      
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
        
        redirect_to quotes_path
      else
        @products = current_user.products
        render :new
      end
    rescue JSON::ParserError => e
      @products = current_user.products
      flash.now[:alert] = "Error al procesar los datos: #{e.message}"
      render :new
    end
  end
  
  def edit
    @products = current_user.products
    # Get list of products already in the quote
    @quote_product_ids = @quote.products.pluck(:id)
  end
  
  def update
    begin
      quote_data = params[:quote_data] ? JSON.parse(params[:quote_data]) : {}
      
      @quote.assign_attributes(
        project_name: quote_data['project_name'],
        customer_name: quote_data['customer_name'],
        organization: quote_data['organization'],
        email: quote_data['email'],
        telephone: quote_data['telephone'],
        comments: quote_data['comments'],
        data: quote_data['data'] || {}
      )
      
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
        
        redirect_to quotes_path, notice: "Cotización actualizada exitosamente."
      else
        @products = current_user.products
        render :edit
      end
    rescue JSON::ParserError => e
      @products = current_user.products
      flash.now[:alert] = "Error al procesar los datos: #{e.message}"
      render :edit
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
  
  # Customer search via Pipedrive
  def search_customer
    query = params[:query]
    
    # Return early if query is too short
    if query.blank? || query.length < 3
      render json: { error: "Search query must be at least 3 characters." }
      return
    end
    
    begin
      # Get API key from database
      api_key = AppConfig.get_pipedrive_api_key
      
      unless api_key
        render json: { error: "Pipedrive API key not configured." }
        return
      end
      
      # Search for persons (customers) in Pipedrive
      url = URI("https://api.pipedrive.com/v1/persons/search?term=#{CGI.escape(query)}&api_token=#{api_key}")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      
      request = Net::HTTP::Get.new(url)
      request["Accept"] = "application/json"
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        customers = []
        
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
        
        render json: { customers: customers }
      else
        render json: { error: "Pipedrive API error: #{response.code}" }
      end
    rescue => e
      Rails.logger.error("Pipedrive API error: #{e.message}")
      render json: { error: "An error occurred while searching for customers: #{e.message}" }
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
      pdf_content = generate_pdf_for_quote(@quote)
      
      QuoteMailer.with(
        quote: @quote,
        user: current_user,
        message: params[:message],
        pdf_content: pdf_content
      ).send_quote.deliver_now
      
      respond_to do |format|
        format.html { redirect_to @quote, notice: 'La cotización ha sido enviada por correo.' }
        format.json { render json: { message: 'Email sent successfully' }, status: :ok }
      end
    rescue => e
      Rails.logger.error "Error sending email: #{e.message}"
      respond_to do |format|
        format.html { redirect_to @quote, alert: 'Error al enviar el correo. Por favor intente nuevamente.' }
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