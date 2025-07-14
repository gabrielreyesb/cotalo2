class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    Rails.logger.info "Admin Dashboard accessed by user: #{current_user.email}"
    @users = User.where(disabled: false)
    @total_users = User.where(disabled: false).count
    @total_products = Product.count
    @total_quotes = Quote.count
  end

  def users
    Rails.logger.info "Admin Users list accessed by user: #{current_user.email}"
    @users = User.where(disabled: false).order(created_at: :desc)
  end

  private

  def require_admin
    Rails.logger.info "Checking admin status for user: #{current_user.email}"
    unless current_user.admin?
      Rails.logger.warn "Non-admin user attempted to access admin area: #{current_user.email}"
      flash[:alert] = "You don't have permission to access this area."
      redirect_to root_path
    end
  end
end
