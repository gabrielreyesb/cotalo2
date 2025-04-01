class Api::V1::AppConfigsController < ApplicationController
  before_action :authenticate_user!
  
  def user_config
    # Get raw values from database
    waste_pct_raw = current_user.get_config(AppConfig::WASTE_PERCENTAGE)
    
    # Convert percentages from decimal (0.05) to whole numbers (5) for the frontend
    waste_pct = waste_pct_raw.nil? ? 5 : (waste_pct_raw * 100).round
    
    # Return the current user's configuration values
    config = {
      waste_percentage: waste_pct,
      width_margin: current_user.get_config(AppConfig::WIDTH_MARGIN) || 0,
      length_margin: current_user.get_config(AppConfig::LENGTH_MARGIN) || 0
    }
    
    render json: config
  end
end 