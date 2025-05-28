class QuoteMailer < ApplicationMailer

  def send_quote
    @quote = params[:quote]
    @user = params[:user]
    @message = params[:message]
    @pdf_content = params[:pdf_content]
    
    Rails.logger.info "Preparing email for quote \\#{@quote.id}"
    Rails.logger.info "PDF content size: \\#{@pdf_content.bytesize} bytes"
    
    @signature_name = @user.get_config('customer_name').presence || "Cotalo"
    @signature_company = @user.get_config('company_name').presence || "Cotalo"
    @logo_url = @user.get_config(AppConfig::COMPANY_LOGO)
    
    begin
      attachments["#{@quote.quote_number}.pdf"] = {
        mime_type: 'application/pdf',
        content: @pdf_content
      }
      Rails.logger.info "PDF attachment added successfully"
    rescue => e
      Rails.logger.error "Error attaching PDF: \\#{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
    
    mail(
      to: @quote.email,
      subject: "Cotización \\#{@quote.quote_number} - \\#{@quote.project_name}"
    )
  end
end 