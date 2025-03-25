class AppConfigsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_api_key]
  
  def edit
    # Get raw percentage values
    waste_pct_raw = current_user.get_config(AppConfig::WASTE_PERCENTAGE)
    margin_pct_raw = current_user.get_config(AppConfig::MARGIN_PERCENTAGE)
    
    # Convert decimal percentages (0.05) to whole numbers (5) for the form
    waste_pct = waste_pct_raw.nil? ? 5 : (waste_pct_raw * 100).round
    margin_pct = margin_pct_raw.nil? ? 30 : (margin_pct_raw * 100).round
    
    # Group configurations by category
    @general_settings = {
      theme_mode: current_user.get_config(AppConfig::THEME_MODE) || AppConfig::THEME_DARK,
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
    
    # Check if Pipedrive API is configured (don't show the actual key)
    @pipedrive_api_configured = AppConfig.get_pipedrive_api_key.present?
  end
  
  def update
    # Update theme settings
    current_user.set_config(AppConfig::THEME_MODE, params[:theme_mode])
    
    # Update general settings
    current_user.set_config(AppConfig::WASTE_PERCENTAGE, params[:waste_percentage], AppConfig::PERCENTAGE)
    current_user.set_config(AppConfig::MARGIN_PERCENTAGE, params[:margin_percentage], AppConfig::PERCENTAGE)
    current_user.set_config(AppConfig::WIDTH_MARGIN, params[:width_margin], AppConfig::NUMERIC)
    current_user.set_config(AppConfig::LENGTH_MARGIN, params[:length_margin], AppConfig::NUMERIC)
    
    # Update sales conditions
    current_user.set_config(AppConfig::SALES_CONDITION_1, params[:condition_1])
    current_user.set_config(AppConfig::SALES_CONDITION_2, params[:condition_2])
    current_user.set_config(AppConfig::SALES_CONDITION_3, params[:condition_3])
    current_user.set_config(AppConfig::SALES_CONDITION_4, params[:condition_4])
    
    # Update signature info
    current_user.set_config(AppConfig::SIGNATURE_NAME, params[:signature_name])
    current_user.set_config(AppConfig::SIGNATURE_EMAIL, params[:signature_email])
    current_user.set_config(AppConfig::SIGNATURE_PHONE, params[:signature_phone])
    current_user.set_config(AppConfig::SIGNATURE_WHATSAPP, params[:signature_whatsapp])
    
    redirect_to edit_app_configs_path, notice: 'Configuration updated successfully'
  end
  
  # Method to update API key
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
      flash[:notice] = "API key updated successfully"
    else
      flash[:alert] = "API key cannot be blank"
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