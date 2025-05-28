class UserMailer < ApplicationMailer

  def welcome_email(user)
    @user = user
    Rails.logger.info "[UserMailer] Sending welcome email to: \\#{@user.email}"
    mail(
      to: @user.email,
      subject: '¡Bienvenido a Cotalo!'
    )
  end
end 