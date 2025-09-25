class RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  respond_to :html, :json

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_to do |format|
          format.html { redirect_to after_sign_up_path_for(resource) }
          format.json { render json: { redirect_to: after_sign_up_path_for(resource) }, status: :ok }
        end
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_to do |format|
          format.html { redirect_to after_inactive_sign_up_path_for(resource) }
          format.json { render json: { redirect_to: after_inactive_sign_up_path_for(resource) }, status: :ok }
        end
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation])
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