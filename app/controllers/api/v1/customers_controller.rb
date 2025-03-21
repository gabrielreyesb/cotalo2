require 'net/http'
require 'uri'
require 'json'
require 'httparty'

class Api::V1::CustomersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:search]

  def search
    # Get API key from database
    api_key = AppConfig.find_by(key: AppConfig::PIPEDRIVE_API_KEY)&.value
    
    if api_key.blank?
      render json: { error: "API key not configured" }, status: :internal_server_error
      return
    end
    
    # Get the customer name from params
    customer_name = params[:customer_name]
    
    if customer_name.blank?
      render json: { error: "Customer name is required" }, status: :bad_request
      return
    end
    
    begin
      # Search for persons (customers) in Pipedrive
      url = URI("https://api.pipedrive.com/v1/persons/search?term=#{CGI.escape(customer_name)}&api_token=#{api_key}")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      
      request = Net::HTTP::Get.new(url)
      request["Accept"] = "application/json"
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        results = []

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

            results << {
              name: person['name'],
              email: email,
              phone: phone,
              organization: person.dig('organization', 'name'),
              organization_id: person.dig('organization', 'value'),
              person_id: person['id']
           }
         end
        end

        render json: { results: results }
      else
        render json: { error: "Pipedrive API error: #{response.code}" }, status: :unprocessable_entity
      end
      
    rescue => e
      render json: { error: "Internal server error", message: e.message }, status: :internal_server_error
    end
  end

  # Public endpoint to verify the Pipedrive API key and return account information
  def verify_pipedrive_account
    # Get the API key from the database
    api_key = AppConfig.find_by(key: AppConfig::PIPEDRIVE_API_KEY)&.value
    
    if api_key.blank?
      render json: { success: false, error: "API key not configured" }
      return
    end

    # Make the API request to verify the account
    begin
      url = "https://api.pipedrive.com/v1/users/me?api_token=#{api_key}"
      response = HTTParty.get(url)
      data = JSON.parse(response.body)
      
      if data["success"]
        # Get the first few characters of the API key for display
        api_key_prefix = "#{api_key[0..3]}...#{api_key[-4..-1]}"
        
        # Return account info
        render json: {
          success: true,
          account_info: {
            name: data["data"]["name"],
            email: data["data"]["email"],
            company: data["data"]["company_name"] || data["data"]["company_id"],
            user_id: data["data"]["id"]
          },
          api_key_prefix: api_key_prefix
        }
      else
        render json: { success: false, error: data["error"] || "Unknown API error", api_key_prefix: "#{api_key[0..3]}..." }
      end
    rescue => e
      render json: { success: false, error: e.message }
    end
  end

  private
  
  # Verify which Pipedrive account is being accessed with the current API key
  def check_pipedrive_account(api_token)
    begin
      # Get information about the current user/account
      url = URI("https://api.pipedrive.com/v1/users/me?api_token=#{api_token}")
      
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      
      request = Net::HTTP::Get.new(url)
      request["Accept"] = "application/json"
      
      response = http.request(request)
      
      if response.code == '200'
        data = JSON.parse(response.body)
        if data['success'] && data['data']
          # Return relevant account information
          {
            name: data['data']['name'],
            email: data['data']['email'], 
            company: data['data']['company_name'] || data['data'].dig('company', 'name'),
            company_id: data['data']['company_id'],
            api_key_valid: true
          }
        else
          { error: "No user data returned", api_key_valid: false }
        end
      else
        { error: "Invalid response: #{response.code}", api_key_valid: false }
      end
    rescue StandardError => e
      Rails.logger.error "Error verifying Pipedrive account: #{e.message}"
      { error: e.message, api_key_valid: false }
    end
  end
end 