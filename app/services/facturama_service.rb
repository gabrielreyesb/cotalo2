require 'net/http'
require 'uri'
require 'json'
require 'base64'

class FacturamaService
  class FacturamaError < StandardError; end

  def initialize(api_key)
    @api_key = api_key
    # Using the production API
    @base_url = 'https://api.facturama.mx'
    
    # Ensure API key is in the correct format (username:password)
    unless @api_key.include?(':')
      raise FacturamaError, "Invalid API key format. Expected format: username:password"
    end
    
    # Create headers with properly encoded API key
    @headers = {
      'Authorization' => "Basic #{Base64.strict_encode64(@api_key)}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end

  # Verify the API key and return account information
  def verify_account
    begin
      # Try to list products as a test of the API connection
      response = make_request(:get, '/products')
      
      if response['data']
        {
          success: true,
          message: 'API connection successful',
          products: response['data']
        }
      else
        {
          success: false,
          error: 'Failed to fetch products'
        }
      end
    rescue => e
      Rails.logger.error "Error verifying account: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        success: false,
        error: e.message
      }
    end
  end

  # List all products from Facturama
  def list_products
    begin
      response = make_request(:get, '/products')
      if response['data']
        {
          success: true,
          products: response['data']
        }
      else
        {
          success: false,
          error: 'Failed to fetch products'
        }
      end
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Create a new product in Facturama
  def create_product(product_data)
    Rails.logger.info "Creating product with data: #{product_data.inspect}"
    
    # Required fields for Facturama API - exactly matching Postman working request
    required_fields = {
      "Unit" => "Pieza",
      "UnitCode" => "H87",
      "Name" => product_data[:name],
      "Description" => product_data[:description],
      "Price" => product_data[:price],
      "CodeProdServ" => "24121503",
      "Taxes" => [
        {
          "Name" => "IVA",
          "Rate" => 0.16,
          "IsRetention" => false,
          "IsFederalTax" => true
        }
      ]
    }

    begin
      Rails.logger.info "Making POST request to /Product with data: #{required_fields.inspect}"
      response = make_request(:post, '/Product', required_fields)
      
      Rails.logger.info "Product creation response: #{response.inspect}"
      
      # Check if response is a Hash and has an Id
      if response.is_a?(Hash) && response['Id']
        {
          success: true,
          product: response
        }
      else
        {
          success: false,
          error: "Invalid response from Facturama API: #{response.inspect}"
        }
      end
    rescue => e
      Rails.logger.error "Error creating product: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      {
        success: false,
        error: "Failed to create product: #{e.message}"
      }
    end
  end

  # Create a new invoice
  def create_invoice(invoice_data)
    begin
      response = make_request(:post, '/api/Invoice', invoice_data)
      if response['success']
        {
          success: true,
          invoice_id: response['data']['id'],
          invoice_number: response['data']['invoice_number']
        }
      else
        {
          success: false,
          error: response['message'] || 'Failed to create invoice'
        }
      end
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end

  # Get invoice status
  def get_invoice_status(invoice_id)
    begin
      response = make_request(:get, "/api/Invoice/#{invoice_id}")
      if response['success']
        {
          success: true,
          status: response['data']['status'],
          invoice_data: response['data']
        }
      else
        {
          success: false,
          error: response['message'] || 'Failed to get invoice status'
        }
      end
    rescue => e
      {
        success: false,
        error: e.message
      }
    end
  end

  private

  def make_request(method, path, body = nil)
    Rails.logger.info "Making #{method.to_s.upcase} request to #{path}"
    Rails.logger.info "Request body: #{body.inspect}" if body

    uri = URI.parse("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.read_timeout = 30
    http.open_timeout = 30

    request = case method
              when :get
                Net::HTTP::Get.new(uri)
              when :post
                Net::HTTP::Post.new(uri)
              when :put
                Net::HTTP::Put.new(uri)
              when :delete
                Net::HTTP::Delete.new(uri)
              end

    # Set headers exactly as in Postman
    request['Authorization'] = "Basic #{Base64.strict_encode64(@api_key)}"
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    
    if body
      request.body = body.to_json
      Rails.logger.info "Request body JSON: #{request.body}"
    end

    Rails.logger.info "Request headers: #{request.to_hash.inspect}"
    Rails.logger.info "API Key format: #{@api_key.include?(':') ? 'Valid (contains :)' : 'Invalid (missing :)'}"
    Rails.logger.info "API Key length: #{@api_key.length}"
    Rails.logger.info "API Key first 4 chars: #{@api_key[0..4]}"

    begin
      response = http.request(request)
      Rails.logger.info "Response status: #{response.code}"
      Rails.logger.info "Response headers: #{response.to_hash.inspect}"
      Rails.logger.info "Response body: #{response.body}"

      # Check if response is HTML (error page)
      if response.body.start_with?('<!DOCTYPE')
        Rails.logger.error "Received HTML response instead of JSON: #{response.body}"
        raise FacturamaError, "Server returned HTML error page instead of JSON"
      end

      case response.code
      when '200', '201', '202'
        begin
          parsed_response = JSON.parse(response.body)
          Rails.logger.info "Parsed response: #{parsed_response.inspect}"
          parsed_response
        rescue JSON::ParserError => e
          Rails.logger.error "Failed to parse JSON response: #{response.body}"
          raise FacturamaError, "Invalid JSON response from API: #{e.message}"
        end
      when '401'
        raise FacturamaError, "Unauthorized: Invalid API credentials. Please check your API key format (username:password)"
      when '404'
        raise FacturamaError, "Resource not found: #{path}"
      when '503'
        raise FacturamaError, "Service temporarily unavailable"
      else
        raise FacturamaError, "API returned status #{response.code}: #{response.body}"
      end
    rescue Net::OpenTimeout => e
      Rails.logger.error "Timeout error: #{e.message}"
      raise FacturamaError, "Request timed out: #{e.message}"
    rescue OpenSSL::SSL::SSLError => e
      Rails.logger.error "SSL error: #{e.message}"
      raise FacturamaError, "SSL error: #{e.message}"
    rescue Errno::ECONNREFUSED => e
      Rails.logger.error "Connection refused: #{e.message}"
      raise FacturamaError, "Could not connect to Facturama API. Please check your internet connection."
    end
  end
end 