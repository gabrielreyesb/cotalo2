class Api::V1::AppConfigsController < ApplicationController
  before_action :authenticate_user!
  
  def user_config
    config = current_user.app_configs.find_by(key: AppConfig::WASTE_PERCENTAGE)
    if config.nil?
      waste_pct = 0
    elsif config.value_type == 'percentage'
      waste_pct = (config.value.to_f * 100).round
    else
      waste_pct = config.value.to_f.round
    end

    render json: {
      waste_percentage: waste_pct,
      width_margin: current_user.get_config(AppConfig::WIDTH_MARGIN) || 0,
      length_margin: current_user.get_config(AppConfig::LENGTH_MARGIN) || 0
    }
  end
end 