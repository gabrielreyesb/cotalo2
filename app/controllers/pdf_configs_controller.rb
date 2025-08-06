class PdfConfigsController < ApplicationController
  require 'fileutils'
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:update_logo]

  def edit
    @pdf_config = current_user.pdf_config || current_user.build_pdf_config
  end

  def update
    @pdf_config = current_user.pdf_config || current_user.build_pdf_config
    
    # Proteger la URL del logo - no permitir que se sobrescriba con valores vacíos
    update_params = pdf_config_params
    
    # Verificar si logo_url está vacío o es nil y hay una URL actual que proteger
    logo_url_param = update_params[:logo_url]
    if logo_url_param.blank? && @pdf_config.logo_url.present?
      update_params.delete(:logo_url)
    elsif logo_url_param.present?
    else
    end
    
    if @pdf_config.update(update_params)
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

        # Upload to Cloudinary
        timestamp = Time.current.to_i
        public_id = "pdf_logos/#{current_user.id}/logo_#{timestamp}"
        
        result = Cloudinary::Uploader.upload(
          params[:logo],
          public_id: public_id,
          folder: "pdf_logos/#{current_user.id}",
          resource_type: :image,
          transformation: [
            { width: 400, height: 400, crop: :limit }
          ]
        )
        
        cloudinary_url = result['secure_url']
        
        pdf_config = current_user.pdf_config || current_user.build_pdf_config
        pdf_config.logo_url = cloudinary_url
        pdf_config.save!

        render json: { success: true, url: cloudinary_url }
      rescue => e
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