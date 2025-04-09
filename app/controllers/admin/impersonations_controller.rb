class Admin::ImpersonationsController < ApplicationController
  before_action :require_admin
  before_action :find_user, only: [:create]

  def create
    if impersonate_user(@user)
      redirect_to root_path, notice: "Now impersonating #{@user.email}"
    else
      redirect_to admin_path, alert: "Could not impersonate user"
    end
  end

  def destroy
    stop_impersonating
    redirect_to admin_path, notice: "Stopped impersonating user"
  end

  private

  def find_user
    @user = User.find(params[:user_id])
  end

  def require_admin
    unless true_user.admin?
      redirect_to root_path, alert: "Not authorized"
    end
  end
end 