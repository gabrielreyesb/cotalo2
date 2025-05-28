class AdminMailer < ApplicationMailer

  def new_user_notification(user)
    @user = user
    Rails.logger.info "[AdminMailer] Sending new user notification for: \\#{@user.email}"
    mail(
      to: 'gabriel@cotalo.app',
      subject: 'Nuevo usuario registrado en Cotalo'
    )
  end

  def new_suggestion_notification(suggestion)
    @suggestion = suggestion
    @user = suggestion.user
    mail(
      to: 'gabriel@cotalo.app',
      subject: 'Nueva sugerencia enviada en Cotalo'
    )
  end
end 