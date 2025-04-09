module UserImpersonation
  extend ActiveSupport::Concern

  included do
    before_action :store_impersonator_id
    helper_method :current_user
    helper_method :true_user
  end

  def impersonate_user(user)
    return false unless true_user.admin?
    session[:impersonated_user_id] = user.id
    session[:true_user_id] = true_user.id unless session[:true_user_id]
  end

  def stop_impersonating
    session.delete(:impersonated_user_id)
  end

  def true_user
    @true_user ||= User.find_by(id: session[:true_user_id]) || current_user
  end

  def current_user
    return super unless session[:impersonated_user_id]
    @current_user ||= User.find_by(id: session[:impersonated_user_id]) || super
  end

  private

  def store_impersonator_id
    @impersonator_id = session[:true_user_id]
  end
end 