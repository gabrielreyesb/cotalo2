class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_user, only: [:show, :edit, :update, :destroy, :toggle_disabled]

  def index
    # Get base users query
    base_query = if params[:show_disabled].present? && params[:show_disabled] == '1'
      User.all
    else
      User.where(disabled: false)
    end
    
    # Get users with counts using separate queries for SQLite compatibility
    @users = base_query.order(created_at: :desc)
    
    # Add counts to each user (excluding demo data created automatically)
    @users.each do |user|
      user.define_singleton_method(:products_count) do
        # Exclude the 3 demo products created automatically using LIKE to match partial names
        user.products.where.not(
          "description LIKE ? OR description LIKE ? OR description LIKE ?",
          'Caja plegadiza cosmética – cartulina caple 12 pts%',
          'Folder corporativo institucional%',
          'Tríptico promocional 21×29.7 cm%'
        ).count
      end
      
      user.define_singleton_method(:quotes_count) do
        # Exclude the 2 demo quotes created automatically
        user.quotes.where.not(project_name: [
          'Caja plegadiza para producto cosmético premium',
          'Campaña de Marketing Corporativo Q4 2024'
        ]).count
      end
    end
    
    @show_disabled = params[:show_disabled].present? && params[:show_disabled] == '1'
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
