class PriceAdjustmentsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_prices]
  
  def edit
    # Get the last adjustment percentage
    @last_adjustment = current_user.get_config(AppConfig::PRICE_ADJUSTMENT_PERCENTAGE) || 0
  end
  
  def update_prices
    begin
      percentage = params[:percentage].to_f
      
      # Update all materials (cost field)
      current_user.materials.find_each do |material|
        base_cost = material.cost || 0
        new_cost = base_cost * (1 + percentage / 100.0)
        material.update!(cost: new_cost)
      end
      
      # Update all processes
      current_user.manufacturing_processes.find_each do |process|
        new_cost = process.cost * (1 + percentage / 100.0)
        process.update!(cost: new_cost)
      end
      
      # Update all indirect costs (extras)
      current_user.indirect_costs.find_each do |extra|
        new_cost = extra.cost * (1 + percentage / 100.0)
        extra.update!(cost: new_cost)
      end
      
      # Store the adjustment percentage
      current_user.set_config(AppConfig::PRICE_ADJUSTMENT_PERCENTAGE, percentage, AppConfig::NUMERIC)
      
      redirect_to edit_price_adjustments_path, notice: "Precios actualizados exitosamente."
    rescue => e
      Rails.logger.error "Error updating prices: #{e.message}"
      redirect_to edit_price_adjustments_path, alert: "Error al actualizar los precios: #{e.message}"
    end
  end
end 