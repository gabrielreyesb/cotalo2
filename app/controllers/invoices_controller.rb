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
    receiver_rfc = "XAXX010101000"
    receiver_fiscal_regime = "616"
    cfdi_use = (receiver_fiscal_regime == "616" || receiver_rfc == "XAXX010101000") ? "S01" : "G03"
    {
      "Serie" => "F",
      "Folio" => invoice.id.to_s,
      "CfdiType" => "I", # Ingreso (income)
      "ExpeditionPlace" => "64000",
      "PaymentForm" => "01",
      "PaymentMethod" => "PUE",
      "Issuer" => {
        "Rfc" => "EKU9003173C9", # Facturama sandbox RFC
        "Name" => "ESCUELA KEMPER URGATE",
        "FiscalRegime" => "601" # General de Ley Personas Morales
      },
      "Receiver" => {
        "Rfc" => receiver_rfc, # Publico en General
        "Name" => "Publico en General",
        "CfdiUse" => cfdi_use,
        "FiscalRegime" => receiver_fiscal_regime, # Sin obligaciones fiscales
        "TaxZipCode" => "64000"
      },
      "Items" => invoice.data["products"].map do |product|
        quantity = product["quantity"].to_f
        unit_price = product["unit_price"].to_f.round(6)
        subtotal = (unit_price * quantity).round(6)
        tax_total = (subtotal * 0.16).round(6)
        total = (subtotal + tax_total).round(6)
        {
          "Quantity" => quantity,
          "ProductCode" => "84111506",
          "UnitCode" => "ACT",
          "Unit" => "Actividad",
          "Description" => product["description"],
          "UnitPrice" => unit_price,
          "Subtotal" => subtotal,
          "Total" => total,
          "TaxObject" => "02", # Required by SAT
          "Taxes" => [
            {
              "Total" => tax_total,
              "Name" => "IVA",
              "Base" => subtotal,
              "Rate" => 0.16,
              "IsRetention" => false
            }
          ]
        }
      end
    }
  end
end
