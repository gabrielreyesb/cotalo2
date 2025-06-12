class DemoRequestMailer < ApplicationMailer
  def new_demo_request(demo_request)
    @demo_request = demo_request
    
    mail(
      to: 'gabriel@cotalo.app',
      subject: "Nueva solicitud de demostración - #{@demo_request.name}"
    )
  end
end
