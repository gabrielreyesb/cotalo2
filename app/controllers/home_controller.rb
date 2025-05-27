class HomeController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard]
  
  def index
  end

  def dashboard
    @user = current_user
    
    # Set trial end date for new users if not set
    if @user.trial_ends_at.nil? && @user.subscription_status == 'trial'
      @user.update(trial_ends_at: 14.days.from_now)
    end
    
    # Quote metrics
    @quotes = @user.quotes
    @total_quotes_value = @quotes.sum { |q| q.data&.dig('totals', 'total') || 0 }
    @average_quote_value = @quotes.any? ? @total_quotes_value / @quotes.count : 0
    @recent_quotes_count = @quotes.where('created_at >= ?', 30.days.ago).count
    @highest_quote = @quotes.max_by { |q| q.data&.dig('totals', 'total') || 0 }
    
    # Product metrics
    @products = @user.products
    @highest_value_products = @products
      .select { |p| p.data&.dig('pricing', 'total_price') }
      .sort_by { |p| p.data&.dig('pricing', 'total_price') || 0 }
      .reverse
      .first(5)
  end
end
