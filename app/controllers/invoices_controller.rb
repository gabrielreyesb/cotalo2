class InvoicesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_quote
  before_action :set_invoice, only: [:show, :status]
  
  def create
    @invoice = @quote.create_invoice
    
    if @invoice.persisted?
      # Get Facturama API key
      api_key = AppConfig.get_facturama_api_key(current_user)
      
      if api_key.blank?
        @invoice.mark_as_cancelled!
        redirect_to quote_path(@quote), alert: 'Facturama API key not configured. Please configure it in settings.'
        return
      end
      
      # Initialize Facturama service
      facturama = FacturamaService.new(api_key)
      
      # Prepare invoice data for Facturama
      invoice_data = prepare_invoice_data(@invoice)
      
      # Create invoice in Facturama
      result = facturama.create_invoice(invoice_data)
      
      if result[:success]
        @invoice.mark_as_created!(result[:invoice_id])
        redirect_to quote_invoice_path(@quote, @invoice), notice: 'Invoice created successfully in Facturama.'
      else
        @invoice.mark_as_cancelled!
        redirect_to quote_path(@quote), alert: "Failed to create invoice in Facturama: #{result[:error]}"
      end
    else
      redirect_to quote_path(@quote), alert: 'Failed to create invoice.'
    end
  end
  
  def show
    if @invoice.created?
      # Get Facturama API key
      api_key = AppConfig.get_facturama_api_key(current_user)
      
      if api_key.present?
        # Initialize Facturama service
        facturama = FacturamaService.new(api_key)
        
        # Get invoice status from Facturama
        result = facturama.get_invoice_status(@invoice.facturama_id)
        
        if result[:success]
          @invoice_status = result[:status]
          @invoice_data = result[:invoice_data]
        else
          @invoice_error = result[:error]
        end
      end
    end
  end
  
  def status
    if @invoice.created?
      # Get Facturama API key
      api_key = AppConfig.get_facturama_api_key(current_user)
      
      if api_key.present?
        # Initialize Facturama service
        facturama = FacturamaService.new(api_key)
        
        # Get invoice status from Facturama
        result = facturama.get_invoice_status(@invoice.facturama_id)
        
        if result[:success]
          render json: { status: result[:status], data: result[:invoice_data] }
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      else
        render json: { error: 'Facturama API key not configured' }, status: :unprocessable_entity
      end
    else
      render json: { status: @invoice.status }
    end
  end
  
  private
  
  def set_quote
    @quote = current_user.quotes.find(params[:quote_id])
  end
  
  def set_invoice
    @invoice = @quote.invoices.find(params[:id])
  end
  
  def prepare_invoice_data(invoice)
    {
      # Basic invoice information
      series: "F", # You might want to make this configurable
      folio: invoice.id.to_s,
      date: Time.current.strftime("%Y-%m-%d"),
      currency: "MXN",
      exchange_rate: 1,
      payment_method: "PUE", # Payment in a single exhibition
      payment_terms: "Immediate",
      
      # Customer information
      customer: {
        tax_id: invoice.data["customer_tax_id"], # You'll need to add this to the quote form
        name: invoice.data["customer_name"],
        email: invoice.data["email"],
        phone: invoice.data["telephone"],
        address: {
          street: invoice.data["customer_address"], # You'll need to add this to the quote form
          exterior_number: invoice.data["customer_exterior_number"], # You'll need to add this to the quote form
          interior_number: invoice.data["customer_interior_number"], # You'll need to add this to the quote form
          neighborhood: invoice.data["customer_neighborhood"], # You'll need to add this to the quote form
          zip_code: invoice.data["customer_zip_code"], # You'll need to add this to the quote form
          locality: invoice.data["customer_locality"], # You'll need to add this to the quote form
          municipality: invoice.data["customer_municipality"], # You'll need to add this to the quote form
          state: invoice.data["customer_state"], # You'll need to add this to the quote form
          country: "México"
        }
      },
      
      # Items (products)
      items: invoice.data["products"].map do |product|
        {
          product_code: "84111506", # You might want to make this configurable per product
          description: product["description"],
          unit: "ACT", # Unit of measurement
          quantity: product["quantity"],
          unit_price: product["unit_price"],
          amount: product["total"],
          tax_rate: 0.16, # 16% VAT
          tax_amount: product["total"] * 0.16,
          total: product["total"] * 1.16
        }
      end,
      
      # Totals
      subtotal: invoice.total,
      tax_rate: 0.16,
      tax_amount: invoice.total * 0.16,
      total: invoice.total * 1.16
    }
  end
end
