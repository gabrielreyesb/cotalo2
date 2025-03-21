def search_customer
  begin
    customer_name = params[:quote][:customer_name]
    
    # Get API key from database or environment variables
    api_token = AppConfig.get_pipedrive_api_key
    
    unless api_token
      render json: { error: "Pipedrive API key not configured." }, 
             status: :internal_server_error
      return
    end
    
    url = URI("https://api.pipedrive.com/v1/persons/search?term=#{CGI.escape(customer_name)}&api_token=#{api_token}")

  end
end 