class SubscriptionMailer < ApplicationMailer
  def subscription_welcome(user)
    @user = user
    mail(
      to: @user.email,
      subject: t('mailers.subscription.welcome_subject')
    )
  end

  def subscription_past_due(user)
    @user = user
    mail(
      to: @user.email,
      subject: t('mailers.subscription.past_due_subject')
    )
  end

  def subscription_canceled(user)
    @user = user
    mail(
      to: @user.email,
      subject: t('mailers.subscription.canceled_subject')
    )
  end

  def subscription_expired(user)
    @user = user
    mail(
      to: @user.email,
      subject: t('mailers.subscription.expired_subject')
    )
  end

  def payment_succeeded(user, invoice)
    @user = user
    @invoice = invoice
    mail(
      to: @user.email,
      subject: t('mailers.subscription.payment_succeeded_subject')
    )
  end

  def payment_failed(user, invoice)
    @user = user
    @invoice = invoice
    mail(
      to: @user.email,
      subject: t('mailers.subscription.payment_failed_subject')
    )
  end
end 