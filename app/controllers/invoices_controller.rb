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
        error_message = result[:error].is_a?(String) ? result[:error] : result[:error].inspect
        error_message = error_message.truncate(300)
        redirect_to quote_path(@quote), alert: "Failed to create invoice in Facturama: #{error_message}"
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
      "Serie" => "F",
      "Folio" => invoice.id.to_s,
      "CfdiType" => "I", # Ingreso (income)
      "ExpeditionPlace" => "64000", # Replace with your postal code
      "PaymentForm" => "01", # Efectivo (cash), adjust as needed
      "PaymentMethod" => "PUE", # Pago en una sola exhibición
      "Issuer" => {
        "Rfc" => "REBG66125A60",
        "Name" => "Gabriel Arturo Reyes Barredo",
        "FiscalRegime" => "605"
      },
      "Receiver" => {
        "Rfc" => invoice.data["customer_tax_id"] || "XAXX010101000",
        "Name" => invoice.data["customer_name"] || "Publico en General",
        "CfdiUse" => "G03",
        "FiscalRegime" => "601", # TODO: Replace or make dynamic as needed
        "TaxZipCode" => "64000"  # TODO: Replace or make dynamic as needed
      },
      "Items" => invoice.data["products"].map do |product|
        {
          "Quantity" => product["quantity"],
          "ProductCode" => "84111506", # SAT code, adjust as needed
          "UnitCode" => "ACT",         # SAT unit code, adjust as needed
          "Unit" => "Actividad",       # Unit name, adjust as needed
          "Description" => product["description"],
          "UnitPrice" => product["unit_price"],
          "Subtotal" => product["unit_price"] * product["quantity"],
          "Total" => product["unit_price"] * product["quantity"],
          "Taxes" => [
            {
              "Total" => product["unit_price"] * product["quantity"] * 0.16,
              "Name" => "IVA",
              "Base" => product["unit_price"] * product["quantity"],
              "Rate" => 0.16,
              "IsRetention" => false
            }
          ]
        }
      end
    }
  end
end
