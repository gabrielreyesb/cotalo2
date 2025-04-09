class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @users = User.all
    @total_users = User.count
    @total_products = Product.count
    @total_quotes = Quote.count
  end

  private

  def require_admin!
    unless current_user&.admin?
      flash[:alert] = "No tienes permiso para acceder a esta sección."
      redirect_to root_path
    end
  end
end 