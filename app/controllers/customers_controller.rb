class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = current_user.customers.order(name: :asc)
    if params[:q].present?
      query = "%#{params[:q]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      if adapter.include?("sqlite")
        @customers = @customers.where("name LIKE ? OR email LIKE ? OR company LIKE ?", query, query, query)
      else
        @customers = @customers.where("name ILIKE ? OR email ILIKE ? OR company ILIKE ?", query, query, query)
      end
    end
    @customers = @customers.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @customer = current_user.customers.build
  end

  def edit
  end

  def create
    @customer = current_user.customers.build(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to customers_path, notice: t('customers.create.success') }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to customers_path, notice: t('customers.update.success') }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to customers_url, notice: t('customers.destroy.success') }
      format.json { head :no_content }
    end
  end

  # Import functionality
  def import
    @validation_summary = flash[:import_summary]
    @has_validated_file = flash[:has_validated_file]
    @validated_file_name = flash[:validated_file_name]
    @validated_file_path = flash[:validated_file_path]
    @original_file_name = flash[:original_file_name]
  end

  # Validate and preview import (upload + validate in one step)
  def validate_upload
    if params[:file].blank?
      redirect_to import_customers_path, alert: "Please select a file"
      return
    end

    uploaded_file = params[:file]
    temp_file_path = Rails.root.join('tmp', "customer_import_#{current_user.id}_#{Time.current.to_i}#{File.extname(uploaded_file.original_filename)}")
    File.open(temp_file_path, 'wb') { |file| file.write(uploaded_file.read) }

    import_service = ImportService.new(current_user, temp_file_path.to_s, 'customers')
    if import_service.process_file && import_service.validate_and_prepare_import
      flash[:import_summary] = import_service.summary
      flash[:has_validated_file] = true
      flash[:validated_file_name] = uploaded_file.original_filename
      flash[:validated_file_path] = temp_file_path.to_s
      flash[:original_file_name] = uploaded_file.original_filename
      redirect_to import_customers_path
    else
      File.delete(temp_file_path) if File.exist?(temp_file_path)
      redirect_to import_customers_path, alert: import_service.errors.join(', ')
    end
  end

  def import_process
    if params[:file].blank? && params[:validated_file_path].blank?
      flash.now[:alert] = "Por favor selecciona un archivo CSV."
      render :import and return
    end

    # Use uploaded file if present, otherwise use temp file path
    if params[:file].present?
      uploaded_file = params[:file]
      temp_file_path = Rails.root.join('tmp', "customer_import_#{current_user.id}_#{Time.current.to_i}.csv")
      File.open(temp_file_path, 'wb') { |f| f.write(uploaded_file.read) }
    else
      temp_file_path = params[:validated_file_path]
    end

    require 'csv'
    rows = CSV.read(temp_file_path, headers: true)
    imported = 0
    updated = 0
    unchanged = 0
    errors = []
    rows.each_with_index do |row, idx|
      email = row['Email'].to_s.downcase
      customer = current_user.customers.find_by(email: email)
      if customer
        customer.assign_attributes(
          name: row['Name'],
          company: row['Company'],
          phone: row['Phone'],
          address: row['Address'],
          notes: row['Notes']
        )
        if customer.changed?
          if customer.valid?
            customer.save!
            updated += 1
          else
            errors << "Fila #{idx+2}: Datos inválidos para el correo #{row['Email']}: #{customer.errors.full_messages.join(', ')}"
          end
        else
          unchanged += 1
        end
        next
      end
      # Create new customer
      customer = current_user.customers.build(
        name: row['Name'],
        company: row['Company'],
        email: row['Email'],
        phone: row['Phone'],
        address: row['Address'],
        notes: row['Notes']
      )
      if customer.valid?
        customer.save!
        imported += 1
      else
        errors << "Fila #{idx+2}: #{customer.errors.full_messages.join(', ')}"
      end
    end

    File.delete(temp_file_path) if File.exist?(temp_file_path)

    # Set variables for view
    @import_results = {
      imported: imported,
      updated: updated,
      unchanged: unchanged,
      errors: errors,
      total_rows: rows.count
    }
    
    @has_import_results = true

    @import_errors = errors
    render :import
  end

  def import_template
    csv_data = ImportService.generate_template('customers', current_user)
    
    respond_to do |format|
      format.csv do
        send_data csv_data, 
                  filename: "customers_import_template_#{Date.current}.csv",
                  type: 'text/csv'
      end
    end
  end

  def clear_import_session
    cleanup_import_session_and_files
    redirect_to import_customers_path, notice: t('customers.import.session_cleared')
  end

  private

  def set_customer
    @customer = current_user.customers.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :email, :phone, :company, :address, :notes)
  end

  # Simplified method to clear import session data
  def clear_import_session_data
    # Clean up the validated file if it exists
    if session[:validated_file_path] && File.exist?(session[:validated_file_path])
      File.delete(session[:validated_file_path])
      Rails.logger.info "[IMPORT] Validated file deleted: #{session[:validated_file_path]}"
    end
    
    session.delete(:validated_file_path)
    session.delete(:validation_summary)
    session.delete(:validation_timestamp)
    Rails.logger.info "[IMPORT] Session data cleared"
  end

  def cleanup_expired_temp_files
    # Clean up temporary files older than 1 hour
    temp_dir = Rails.root.join('tmp')
    cutoff_time = 1.hour.ago
    
    Dir.glob(temp_dir.join("customer_import_*.{xlsx,xls,csv}")).each do |file|
      if File.mtime(file) < cutoff_time
        File.delete(file) if File.exist?(file)
      end
    end
  end

  def cleanup_import_session_and_files
    # Clean up session variables
    clear_import_session_data
    
    # Clean up any legacy temp files for this user (for backward compatibility)
    temp_dir = Rails.root.join('tmp')
    user_id = current_user.id
    
    Dir.glob(temp_dir.join("customer_import_#{user_id}_*")).each do |file|
      File.delete(file) if File.exist?(file)
    end
  end
end 