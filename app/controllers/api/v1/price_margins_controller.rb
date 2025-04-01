class Api::V1::PriceMarginsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @price_margins = current_user.price_margins.order(:min_price)
    render json: @price_margins
  end
end 