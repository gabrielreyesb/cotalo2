class RegistrationsController < Devise::RegistrationsController
  protected

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