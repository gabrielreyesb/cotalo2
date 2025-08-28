class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :company, :phone, :email, :password, :password_confirmation, :current_password])
  end

  def after_sign_up_path_for(resource)
    flash.delete(:notice)
    
    # Debug logging
    Rails.logger.info "[RegistrationsController] after_sign_up_path_for called for: #{resource.email}"
    Rails.logger.info "[RegistrationsController] Setting session[:new_user] = true"
    
    # Set a flag to indicate this is a new user
    session[:new_user] = true
    
    # New users should always go to onboarding
    onboarding_path
  end

  def after_update_path_for(resource)
    flash.delete(:notice)
    dashboard_path
  end
end 