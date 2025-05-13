class CustomFailureApp < Devise::FailureApp
  def redirect_url
    if warden_message == :account_disabled
      flash[:alert] = I18n.t('devise.failure.account_disabled')
    end
    super
  end

  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end 