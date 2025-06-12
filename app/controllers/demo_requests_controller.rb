class DemoRequestsController < ApplicationController
  def new
    @demo_request = DemoRequest.new
  end

  def create
    @demo_request = DemoRequest.new(demo_request_params)
    
    if @demo_request.save
      # Send email notification
      DemoRequestMailer.new_demo_request(@demo_request).deliver_now
      
      redirect_to demo_request_success_path, notice: '¡Gracias! Tu solicitud de demostración ha sido enviada. Nos pondremos en contacto contigo pronto.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def success
    # This action just renders the success page
  end

  private

  def demo_request_params
    params.require(:demo_request).permit(:name, :email, :company, :phone, :message)
  end
end
