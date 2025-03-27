require 'net/http'
require 'uri'
require 'json'
require 'base64'

class FacturamaService
  class FacturamaError < StandardError; end

  def initialize(api_key)
    @api_key = api_key
    @base_url = 'https://api.facturama.mx/api'
    @headers = {
      'Authorization' => "Basic #{Base64.strict_encode64(@api_key + ':')}",
      'Content-Type' => 'application/json'
    }
  end

  # Verify the API key and return account information
  def verify_account
    begin
      response = make_request(:get, '/api/Account/Verify')
      if response['success']
        {
          success: true,
          account_info: {
            name: response['data']['name'],
            email: response['data']['email'],
            company: response['data']['company_name']
          }
        }
      else
        {
          success: false,
          error: response['message'] || 'Unknown API error'
        }
      end
    rescue => e
      {
        success: false,
        error: e.message
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
    uri = URI.parse(@base_url + path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

    request = case method
              when :get
                Net::HTTP::Get.new(uri)
              when :post
                Net::HTTP::Post.new(uri)
                request.body = body.to_json if body
              end

    @headers.each do |key, value|
      request[key] = value
    end

    response = http.request(request)
    JSON.parse(response.body)
  rescue => e
    raise FacturamaError, "API request failed: #{e.message}"
  end
end 