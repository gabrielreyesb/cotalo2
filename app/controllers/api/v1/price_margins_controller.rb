class Api::V1::PriceMarginsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @price_margins = current_user.price_margins.order(:min_price)
    render json: @price_margins
  end

  def calculate
    price = params[:price].to_f
    price_margin = current_user.price_margins
      .where('min_price <= ?', price)
      .order(min_price: :desc)
      .first

    if price_margin
      render json: { margin_percentage: price_margin.margin_percentage }
    else
      render json: { margin_percentage: 0 }
    end
  end
end 