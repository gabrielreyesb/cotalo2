class ApplicationController < ActionController::Base
  include UserImpersonation
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :skip_authentication?
  before_action :set_cors_headers
  before_action :set_locale
  before_action :skip_trackable_for_impersonation

  # Redirect to dashboard after sign in
  def after_sign_in_path_for(resource)
    flash.delete(:notice)
    dashboard_path
  end

  # Redirect to dashboard after sign up (new account creation)
  def after_sign_up_path_for(resource)
    flash.delete(:notice)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    flash.delete(:notice)
    root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
  
  def skip_authentication?
    devise_controller? || (controller_name == 'home' && action_name == 'index') || controller_name == 'demo_requests'
  end
  
  # Add CORS headers for Vue/API interactions
  def set_cors_headers
    if request.xhr? || request.format.json?
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS, PUT, PATCH, DELETE'
      headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Auth-Token, Origin, Authorization'
    end
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  # Skip Devise trackable if impersonating
  def skip_trackable_for_impersonation
    if session[:impersonated_user_id]
      request.env['devise.skip_trackable'] = true
    end
  end
end
