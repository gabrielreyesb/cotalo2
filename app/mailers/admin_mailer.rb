class AdminMailer < ApplicationMailer
  default from: 'gabriel@cotalo.app'

  def new_user_notification(user)
    @user = user
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