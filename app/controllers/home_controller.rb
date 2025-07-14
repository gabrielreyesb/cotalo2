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
  end

  def about
  end
end
