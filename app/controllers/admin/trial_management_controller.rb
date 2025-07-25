class Admin::TrialManagementController < AdminController
  before_action :set_user, only: [:extend_trial, :reset_trial, :disable_trial]

  def index
    @users = User.where(subscription_status: 'trial')
                 .includes(:products, :quotes)
                 .order(:created_at)
                 .page(params[:page])
                 .per(20)
  end

  def extend_trial
    days = params[:days].to_i
    return redirect_to admin_trial_management_index_path, alert: 'Días inválidos' if days <= 0

    new_trial_end = @user.trial_ends_at + days.days
    @user.update(trial_ends_at: new_trial_end)

    redirect_to admin_trial_management_index_path, 
                notice: "Período de prueba extendido #{days} días para #{@user.email}"
  end

  def reset_trial
    @user.update(
      trial_ends_at: 14.days.from_now,
      subscription_status: 'trial'
    )

    redirect_to admin_trial_management_index_path, 
                notice: "Período de prueba reiniciado para #{@user.email}"
  end

  def disable_trial
    @user.update(
      trial_ends_at: Time.current,
      subscription_status: 'expired'
    )

    redirect_to admin_trial_management_index_path, 
                notice: "Período de prueba deshabilitado para #{@user.email}"
  end

  def bulk_extend_trial
    days = params[:days].to_i
    return redirect_to admin_trial_management_index_path, alert: 'Días inválidos' if days <= 0

    user_ids = params[:user_ids] || []
    updated_count = 0

    User.where(id: user_ids, subscription_status: 'trial').find_each do |user|
      new_trial_end = user.trial_ends_at + days.days
      user.update(trial_ends_at: new_trial_end)
      updated_count += 1
    end

    redirect_to admin_trial_management_index_path, 
                notice: "Período de prueba extendido #{days} días para #{updated_count} usuarios"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end 