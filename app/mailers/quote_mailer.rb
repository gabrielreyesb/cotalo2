class QuoteMailer < ApplicationMailer
  default from: 'gabriel@cotalo.app'

  def send_quote
    @quote = params[:quote]
    @user = params[:user]
    @message = params[:message]
    @pdf_content = params[:pdf_content]
    
    Rails.logger.info "Preparing email for quote #{@quote.id}"
    Rails.logger.info "PDF content size: #{@pdf_content.bytesize} bytes"
    
    begin
      attachments["#{@quote.quote_number}.pdf"] = {
        mime_type: 'application/pdf',
        content: @pdf_content
      }
      Rails.logger.info "PDF attachment added successfully"
    rescue => e
      Rails.logger.error "Error attaching PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
    
    mail(
      to: @quote.email,
      subject: "Cotización #{@quote.quote_number} - #{@quote.project_name}"
    )
  end
end 