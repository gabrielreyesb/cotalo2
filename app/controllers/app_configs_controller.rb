class AppConfigsController < ApplicationController
  before_action :authenticate_user!
  
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
  end
  
  def update
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
end 