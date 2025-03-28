class AppConfigsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_api_key, :test_facturama_api]
  
  def edit
    # Get raw percentage values
    waste_pct_raw = current_user.get_config(AppConfig::WASTE_PERCENTAGE)
    margin_pct_raw = current_user.get_config(AppConfig::MARGIN_PERCENTAGE)
    
    # Convert decimal percentages (0.05) to whole numbers (5) for the form
    waste_pct = waste_pct_raw.nil? ? 5 : (waste_pct_raw * 100).round
    margin_pct = margin_pct_raw.nil? ? 30 : (margin_pct_raw * 100).round
    
    # Group configurations by category
    @general_settings = {
      waste_percentage: waste_pct,
      margin_percentage: margin_pct,
      width_margin: current_user.get_config(AppConfig::WIDTH_MARGIN) || 0,
      length_margin: current_user.get_config(AppConfig::LENGTH_MARGIN) || 0
    }
    
    @sales_conditions = {
      condition_1: current_user.get_config(AppConfig::SALES_CONDITION_1) || '',
      condition_2: current_user.get_config(AppConfig::SALES_CONDITION_2) || '',
      condition_3: current_user.get_config(AppConfig::SALES_CONDITION_3) || '',
      condition_4: current_user.get_config(AppConfig::SALES_CONDITION_4) || ''
    }
    
    @signature_info = {
      name: current_user.get_config(AppConfig::SIGNATURE_NAME) || '',
      email: current_user.get_config(AppConfig::SIGNATURE_EMAIL) || '',
      phone: current_user.get_config(AppConfig::SIGNATURE_PHONE) || '',
      whatsapp: current_user.get_config(AppConfig::SIGNATURE_WHATSAPP) || ''
    }
    
    # Check if APIs are configured (don't show the actual keys)
    @pipedrive_api_configured = AppConfig.get_pipedrive_api_key.present?
    @facturama_api_configured = AppConfig.get_facturama_api_key.present?

    # Create a proper app_config object for the form
    @app_config = OpenStruct.new(
      waste_percentage: @general_settings[:waste_percentage],
      margin_percentage: @general_settings[:margin_percentage],
      width_margin: @general_settings[:width_margin],
      length_margin: @general_settings[:length_margin],
      signature_name: @signature_info[:name],
      signature_email: @signature_info[:email],
      signature_phone: @signature_info[:phone],
      signature_whatsapp: @signature_info[:whatsapp],
      condition_1: @sales_conditions[:condition_1],
      condition_2: @sales_conditions[:condition_2],
      condition_3: @sales_conditions[:condition_3],
      condition_4: @sales_conditions[:condition_4]
    )
  end
  
  def test_facturama_api
    api_key = AppConfig.get_facturama_api_key
    if api_key.blank?
      render json: { success: false, error: "Facturama API key is not configured" }, status: :unprocessable_entity
      return
    end

    begin
      # Initialize Facturama service
      facturama = FacturamaService.new(api_key)
      
      # Test the connection by listing products
      result = facturama.verify_account
      
      if result[:success]
        render json: {
          success: true,
          message: result[:message],
          products: result[:products]
        }
      else
        render json: { success: false, error: result[:error] }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Error testing Facturama API: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: "Failed to test API connection: #{e.message}" }, status: :unprocessable_entity
    end
  end
  
  def test_create_product
    api_key = AppConfig.get_facturama_api_key
    if api_key.blank?
      render json: { success: false, error: "Facturama API key is not configured" }, status: :unprocessable_entity
      return
    end

    # Log the API key being used (first few characters only for security)
    Rails.logger.info "Using Facturama API key: #{api_key[0..4]}..."

    begin
      # Initialize Facturama service
      facturama_service = FacturamaService.new(api_key)

      # Permit the product parameters
      product_params = params.permit(:name, :description, :price)

      Rails.logger.info "Creating product with params: #{product_params.inspect}"
      
      # Create the product
      result = facturama_service.create_product(product_params)
      
      if result[:success]
        render json: { success: true, product: result[:product] }
      else
        render json: { success: false, error: result[:error] }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Error creating product: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { success: false, error: "Failed to create product: #{e.message}" }, status: :unprocessable_entity
    end
  end
  
  def update
    # Update general settings
    if params[:waste_percentage].present?
      current_user.set_config(AppConfig::WASTE_PERCENTAGE, params[:waste_percentage].to_f / 100, AppConfig::PERCENTAGE)
    end
    
    if params[:margin_percentage].present?
      current_user.set_config(AppConfig::MARGIN_PERCENTAGE, params[:margin_percentage].to_f / 100, AppConfig::PERCENTAGE)
    end
    
    if params[:width_margin].present?
      current_user.set_config(AppConfig::WIDTH_MARGIN, params[:width_margin].to_f, AppConfig::NUMERIC)
    end
    
    if params[:length_margin].present?
      current_user.set_config(AppConfig::LENGTH_MARGIN, params[:length_margin].to_f, AppConfig::NUMERIC)
    end
    
    # Update signature information
    if params[:signature_name].present?
      current_user.set_config(AppConfig::SIGNATURE_NAME, params[:signature_name])
    end
    
    if params[:signature_email].present?
      current_user.set_config(AppConfig::SIGNATURE_EMAIL, params[:signature_email])
    end
    
    if params[:signature_phone].present?
      current_user.set_config(AppConfig::SIGNATURE_PHONE, params[:signature_phone])
    end
    
    if params[:signature_whatsapp].present?
      current_user.set_config(AppConfig::SIGNATURE_WHATSAPP, params[:signature_whatsapp])
    end
    
    # Update sales conditions
    if params[:condition_1].present?
      current_user.set_config(AppConfig::SALES_CONDITION_1, params[:condition_1])
    end
    
    if params[:condition_2].present?
      current_user.set_config(AppConfig::SALES_CONDITION_2, params[:condition_2])
    end
    
    if params[:condition_3].present?
      current_user.set_config(AppConfig::SALES_CONDITION_3, params[:condition_3])
    end
    
    if params[:condition_4].present?
      current_user.set_config(AppConfig::SALES_CONDITION_4, params[:condition_4])
    end
    
    redirect_to edit_app_configs_path, notice: 'Configurations updated successfully'
  end
  
  # Method to update API keys
  def update_api_key
    if params[:pipedrive_api_key].present?
      # Simply save the key directly to the user's record
      key_value = params[:pipedrive_api_key].strip
      
      # Clear any existing records
      AppConfig.where(key: AppConfig::PIPEDRIVE_API_KEY).delete_all
      
      # Create a fresh record with the exact key from the form
      AppConfig.create!(
        key: AppConfig::PIPEDRIVE_API_KEY,
        value: key_value,
        user_id: current_user.id
      )
      
      # Show the saved key in a flash message
      flash[:notice] = "Pipedrive API key updated successfully"
    end
    
    if params[:facturama_api_key].present?
      # Validate API key format
      key_value = params[:facturama_api_key].strip
      
      unless key_value.include?(':')
        flash[:error] = "Invalid Facturama API key format. Expected format: username:password"
        redirect_to edit_app_configs_path
        return
      end
      
      # Clear any existing records
      AppConfig.where(key: AppConfig::FACTURAMA_API_KEY).delete_all
      
      # Create a fresh record with the exact key from the form
      AppConfig.create!(
        key: AppConfig::FACTURAMA_API_KEY,
        value: key_value,
        user_id: current_user.id
      )
      
      # Show the saved key in a flash message
      flash[:notice] = "Facturama API key updated successfully"
    end
    
    redirect_to edit_app_configs_path
  end
  
  private
  
  def update_env_file(key, value)
    # Get the path to the .env file
    env_file = Rails.root.join('.env')
    
    if File.exist?(env_file)
      # Read the current contents
      content = File.read(env_file)
      
      # Check if the key already exists
      if content.match(/^#{key}=/)
        # Replace the existing key
        updated_content = content.gsub(/^#{key}=.*$/, "#{key}=#{value}")
      else
        # Add the key at the end
        updated_content = content.strip + "\n#{key}=#{value}\n"
      end
      
      # Write the updated content back to the file
      File.write(env_file, updated_content)
    else
      # Create a new .env file
      File.write(env_file, "#{key}=#{value}\n")
    end
  end
end 