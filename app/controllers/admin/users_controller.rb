class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_disabled]

  def index
    if params[:show_disabled].present? && params[:show_disabled] == '1'
      @users = User.all.order(created_at: :desc)
      @show_disabled = true
    else
      @users = User.where(disabled: false).order(created_at: :desc)
      @show_disabled = false
    end
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: t('admin.users.update.success')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.destroy
      redirect_to admin_users_path, notice: t('admin.users.destroy.success')
    else
      redirect_to admin_users_path, alert: @user.errors.full_messages.join(', ')
    end
  end

  def toggle_disabled
    @user.update(disabled: !@user.disabled)
    status = @user.disabled? ? 'disabled' : 'enabled'
    redirect_to admin_users_path, notice: t("admin.users.toggle_disabled.#{status}")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :admin)
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = t('admin.access_denied')
      redirect_to root_path
    end
  end
end
