require 'roo'
require 'csv'

class ImportService
  attr_reader :errors, :warnings, :import_data, :summary

  def initialize(user, file_path, data_type = 'customers')
    @user = user
    @file_path = file_path
    @data_type = data_type
    @errors = []
    @warnings = []
    @import_data = []
    @summary = {}
  end

  def process_file
    @summary = {}
    @errors = []
    # If no file path is provided, skip file processing (used for import_process)
    if @file_path.nil?
      @errors << "No file path provided"
      return false
    end
    unless File.exist?(@file_path)
      @errors << "File does not exist: #{@file_path}"
      return false
    end
    file_extension = File.extname(@file_path).downcase
    unless ['.xlsx', '.xls', '.csv'].include?(file_extension)
      @errors << "Invalid file format. Please use Excel (.xlsx, .xls) or CSV files only"
      return false
    end
    file_size = File.size(@file_path)
    if file_size == 0
      @errors << "File is empty"
      return false
    end
    if file_size > 10.megabytes
      @errors << "File is too large. Maximum size is 10MB"
      return false
    end
    begin
      case @data_type
      when 'customers'
        process_customers_file
      else
        @errors << "Unsupported data type: #{@data_type}"
        return false
      end
      true
    rescue => e
      @errors << "Error processing file: #{e.message}"
      @summary = {}
      return false
    end
  end

  def validate_and_prepare_import
    return false if @import_data.empty?
    
    case @data_type
    when 'customers'
      validate_customers_data
    else
      @errors << "Unsupported data type: #{@data_type}"
      return false
    end
    
    @errors.empty?
  end

  def execute_import
    return false unless validate_and_prepare_import
    
    begin
      case @data_type
      when 'customers'
        import_customers
      else
        @errors << "Unsupported data type: #{@data_type}"
        return false
      end
      
      true
    rescue => e
      @errors << "Error during import: #{e.message}"
      false
    end
  end

  def validation_status_message
    case @summary[:validation_status]
    when 'passed'
      "Validation passed successfully. Ready to import #{@summary[:valid_rows]} customers."
    when 'failed'
      "Validation failed. #{@summary[:invalid_rows]} rows have errors that need to be fixed."
    when 'warning'
      "Validation warning. No valid data found to import."
    else
      "Validation pending."
    end
  end

  def can_proceed_with_import?
    @summary['validation_status'] == 'passed' && @summary['valid_rows'] > 0
  end

  private

  def process_customers_file
    file_extension = File.extname(@file_path).downcase
    
    if file_extension == '.csv'
      process_csv_customers
    else
      process_excel_customers
    end
  end

  def process_excel_customers
    spreadsheet = Roo::Spreadsheet.open(@file_path)
    sheet = spreadsheet.sheet(0)
    
    headers = sheet.row(1).map(&:to_s).map(&:strip)
    validate_customer_headers(headers)
    
    (2..sheet.last_row).each do |row_number|
      row_data = sheet.row(row_number)
      next if row_data.all?(&:nil?) || row_data.all? { |cell| cell.to_s.strip.empty? }
      
      customer_data = {
        'row_number' => row_number,
        'name' => row_data[0]&.to_s&.strip,
        'company' => row_data[1]&.to_s&.strip,
        'email' => row_data[2]&.to_s&.strip,
        'phone' => row_data[3]&.to_s&.strip,
        'address' => row_data[4]&.to_s&.strip,
        'notes' => row_data[5]&.to_s&.strip
      }
      
      @import_data << customer_data
    end
    
    if @import_data.empty?
      @errors << "No data found in the file"
    end
  end

  def process_csv_customers
    csv_data = CSV.read(@file_path, headers: true)
    headers = csv_data.headers.map(&:to_s).map(&:strip)
    validate_customer_headers(headers)
    
    csv_data.each_with_index do |row, index|
      row_number = index + 2 # +2 because we skip header and CSV is 0-indexed
      next if row.to_h.values.all?(&:nil?) || row.to_h.values.all? { |cell| cell.to_s.strip.empty? }
      
      customer_data = {
        'row_number' => row_number,
        'name' => row[0]&.to_s&.strip,
        'company' => row[1]&.to_s&.strip,
        'email' => row[2]&.to_s&.strip,
        'phone' => row[3]&.to_s&.strip,
        'address' => row[4]&.to_s&.strip,
        'notes' => row[5]&.to_s&.strip
      }
      
      @import_data << customer_data
    end
    
    if @import_data.empty?
      @errors << "No data found in the file"
    end
  end

  def validate_customer_headers(headers)
    expected_headers = ['Name', 'Company', 'Email', 'Phone', 'Address', 'Notes']
    actual_headers = headers.first(6)
    
    unless actual_headers == expected_headers
      @errors << "Invalid headers. Expected: #{expected_headers.join(', ')}. Got: #{actual_headers.join(', ')}"
    end
  end

  def validate_customers_data
    @summary = {
      'total_rows' => @import_data.length,
      'valid_rows' => 0,
      'invalid_rows' => 0,
      'duplicate_rows' => 0,
      'new_customers' => 0,
      'existing_customers' => 0,
      'updated_customers' => 0,
      'validation_status' => 'pending'
    }
    
    existing_customers = @user.customers.index_by { |c| c.email&.downcase }
    
    @import_data.each do |customer_data|
      customer_data = customer_data.transform_keys(&:to_s)
      validation_errors = validate_customer_row(customer_data)
      
      if validation_errors.any?
        customer_data['errors'] = validation_errors
        customer_data['status'] = 'invalid'
        @summary['invalid_rows'] += 1
      elsif customer_data['email'].present? && existing_customers[customer_data['email'].downcase]
        existing_customer = existing_customers[customer_data['email'].downcase]
        # Compare fields to see if there are actual changes
        fields = %w[name company phone address notes]
        has_changes = fields.any? { |f| (customer_data[f] || "").to_s.strip != (existing_customer.send(f) || "").to_s.strip }
        if has_changes
          customer_data['duplicate'] = true
          customer_data['existing_customer'] = existing_customer
          customer_data['warnings'] = ["Customer with this email already exists - will be updated"]
          customer_data['status'] = 'update'
          customer_data.delete('errors')
          @summary['duplicate_rows'] += 1
          @summary['existing_customers'] += 1
          @summary['updated_customers'] += 1
        else
          # No changes, skip update
          customer_data['status'] = 'no_change'
          customer_data.delete('errors')
          @summary['existing_customers'] += 1
        end
      else
        customer_data['status'] = 'valid'
        customer_data.delete('errors')
        @summary['valid_rows'] += 1
        @summary['new_customers'] += 1
      end
    end
    
    if @summary['invalid_rows'] == 0 && (@summary['valid_rows'] > 0 || @summary['updated_customers'] > 0)
      @summary['validation_status'] = 'passed'
    elsif @summary['invalid_rows'] > 0
      @summary['validation_status'] = 'failed'
    else
      @summary['validation_status'] = 'warning'
    end
  end

  def validate_customer_row(customer_data)
    errors = []
    
    errors << "Name is required" if customer_data['name'].blank?
    errors << "Email is required" if customer_data['email'].blank?
    if customer_data['email'].present? && !(customer_data['email'] =~ URI::MailTo::EMAIL_REGEXP)
      errors << "Invalid email format"
    end
    # Puedes agregar aquí otros campos requeridos si lo deseas
    errors
  end

  def import_customers
    @import_data = @import_data.map { |row| row.transform_keys(&:to_s) }
    before_count = @user.customers.count
    Rails.logger.debug "[IMPORT] Customer count before transaction: \\#{before_count}"
    # DEBUG: Remove transaction block for testing
    # ActiveRecord::Base.transaction do
    @import_data.each do |customer_data|
      Rails.logger.debug "[IMPORT] Processing row: #{customer_data.inspect}"
      next if customer_data['errors']&.any?
      
      if customer_data['status'] == 'update' && customer_data['existing_customer']
        Rails.logger.debug "[IMPORT] Updating existing customer: #{customer_data['email']}"
        existing_customer = customer_data['existing_customer']
        unless existing_customer.update(
          name: customer_data['name'],
          company: customer_data['company'],
          email: customer_data['email'],
          phone: customer_data['phone'],
          address: customer_data['address'],
          notes: customer_data['notes']
        )
          customer_data['errors'] = existing_customer.errors.full_messages
          @summary['invalid_rows'] += 1
          @summary['updated_customers'] -= 1
          Rails.logger.error "[IMPORT] Failed to update customer: #{existing_customer.errors.full_messages.join(', ')}"
        end
      elsif customer_data['status'] == 'valid'
        Rails.logger.debug "[IMPORT] Creating new customer: #{customer_data['email']}"
        customer = @user.customers.build(
          name: customer_data['name'],
          company: customer_data['company'],
          email: customer_data['email'],
          phone: customer_data['phone'],
          address: customer_data['address'],
          notes: customer_data['notes']
        )
        begin
          save_result = customer.save!
          Rails.logger.debug "[IMPORT] customer.save! result: \\#{save_result} for email: \\#{customer.email}"
        rescue => e
          Rails.logger.error "[IMPORT] Exception on customer.save!: \\#{e.message} for email: \\#{customer.email}"
          Rails.logger.error "[IMPORT] Validation errors: \\#{customer.errors.full_messages.join(', ')}"
          customer_data['errors'] = customer.errors.full_messages
          @summary['invalid_rows'] += 1
          @summary['valid_rows'] -= 1
          @summary['new_customers'] -= 1
        end
      end
    end
    #   if @import_data.any? { |data| data['errors']&.any? }
    #     error_rows = @import_data.select { |data| data['errors']&.any? }
    #     error_messages = error_rows.map do |row|
    #       "Fila #{row['row_number']}: #{row['errors'].join('; ')}"
    #     end
    #     Rails.logger.error "[IMPORT] Transaction rollback due to errors in import_data: #{error_messages.join(' | ')}"
    #     @errors << "La importación fue cancelada porque se encontraron errores en las siguientes filas: #{error_messages.join(' | ')}"
    #     raise ActiveRecord::Rollback
    #   end
    # end
    after_count = @user.customers.count
    Rails.logger.debug "[IMPORT] Customer count after transaction: \\#{after_count}"
    Rails.logger.debug "[IMPORT] Import summary after transaction: #{@summary.inspect}"
    Rails.logger.debug "[IMPORT] @import_data after transaction: #{@import_data.inspect}"
  end

  def self.generate_template(data_type = 'customers', user = nil)
    case data_type
    when 'customers'
      generate_customers_template_with_data(user)
    else
      raise "Unsupported data type: #{data_type}"
    end
  end

  def self.generate_customers_template(user = nil)
    case data_type
    when 'customers'
      generate_customers_template_with_data(user)
    else
      raise "Unsupported data type: #{data_type}"
    end
  end

  def self.generate_customers_template_with_data(user = nil)
    headers = ['Name', 'Company', 'Email', 'Phone', 'Address', 'Notes']
    
    # Generate a template with example data, not existing customer data
    example_data = [
      ['John Doe', 'Acme Corp', 'john@example.com', '+1-555-0123', '123 Main St, City, State', 'Important client'],
      ['Jane Smith', 'Tech Solutions', 'jane@example.com', '+1-555-0456', '456 Oak Ave, City, State', ''],
      ['Bob Johnson', '', 'bob@example.com', '', '', 'New prospect']
    ]
    
    CSV.generate do |csv|
      csv << headers
      example_data.each { |row| csv << row }
    end
  end
end 