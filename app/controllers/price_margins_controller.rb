class PriceMarginsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_price_margin, only: [:edit, :update, :destroy]
  
  def index
    @price_margins = current_user.price_margins.order(:min_price)
    
    respond_to do |format|
      format.html
      format.json { render json: @price_margins }
    end
  end
  
  def new
    @price_margin = current_user.price_margins.build
  end
  
  def create
    @price_margin = current_user.price_margins.build(price_margin_params)
    
    if @price_margin.save
      redirect_to price_margins_path, notice: t('price_margins.create.success')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @price_margin.update(price_margin_params)
      redirect_to price_margins_path, notice: t('price_margins.update.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @price_margin.destroy
    redirect_to price_margins_path, notice: t('price_margins.destroy.success')
  end
  
  def calculate
    price = params[:price].to_f
    margin = current_user.price_margins.where("min_price <= ? AND max_price >= ?", price, price).first
    render json: { margin_percentage: margin&.margin_percentage || 0 }
  end
  
  private
  
  def set_price_margin
    @price_margin = current_user.price_margins.find(params[:id])
  end
  
  def price_margin_params
    params.require(:price_margin).permit(:min_price, :max_price, :margin_percentage)
  end
end
