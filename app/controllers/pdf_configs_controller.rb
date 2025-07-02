class PdfConfigsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_logo]

  def edit
    @pdf_config = current_user.pdf_config || current_user.build_pdf_config
  end

  def update
    @pdf_config = current_user.pdf_config || current_user.build_pdf_config
    if @pdf_config.update(pdf_config_params)
      redirect_to edit_pdf_config_path, notice: t('pdf_configs.update.success')
    else
      render :edit
    end
  end

  def update_logo
    if params[:logo].present?
      begin
        unless params[:logo].content_type.in?(%w[image/jpeg image/png image/gif])
          render json: { success: false, error: 'Tipo de archivo no válido. Por favor sube una imagen JPG, PNG o GIF.' }, status: :unprocessable_entity
          return
        end

        if params[:logo].size > 2.megabytes
          render json: { success: false, error: 'El archivo es demasiado grande. El tamaño máximo es 2MB.' }, status: :unprocessable_entity
          return
        end

        result = Cloudinary::Uploader.upload(
          params[:logo].tempfile,
          folder: "pdf_logos/#{current_user.id}",
          public_id: "logo_#{Time.current.to_i}",
          overwrite: true,
          resource_type: :auto
        )

        pdf_config = current_user.pdf_config || current_user.build_pdf_config
        pdf_config.logo_url = result['secure_url']
        pdf_config.save!

        render json: { success: true, url: result['secure_url'] }
      rescue => e
        Rails.logger.error "Error uploading PDF logo: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        render json: { success: false, error: "Error interno del servidor: #{e.message}" }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: 'No se ha seleccionado ningún archivo' }, status: :unprocessable_entity
    end
  end

  private

  def pdf_config_params
    params.require(:pdf_config).permit(
      :footer_text, :logo_url, :signature_name, :signature_email, :signature_phone, :signature_whatsapp,
      :sales_condition_1, :sales_condition_2, :sales_condition_3, :sales_condition_4
    )
  end
end 