require 'csv'

class CustomerCsvImportService
  attr_reader :user, :file_path, :errors, :summary

  def initialize(user, file_path)
    @user = user
    @file_path = file_path
    @errors = []
    @summary = { total: 0, imported: 0, failed: 0, duplicates: 0 }
  end

  def import
    unless File.exist?(file_path)
      @errors << "File does not exist: #{file_path}"
      return false
    end

    rows = CSV.read(file_path, headers: true)
    @summary[:total] = rows.size
    existing_emails = user.customers.pluck(:email).map(&:downcase)

    rows.each_with_index do |row, idx|
      email = row['Email'].to_s.downcase
      if existing_emails.include?(email)
        @errors << "Fila #{idx+2}: Duplicado - ya existe un cliente con el correo #{row['Email']}"
        @summary[:duplicates] += 1
        @summary[:failed] += 1
        next
      end
      customer = user.customers.build(
        name: row['Name'],
        company: row['Company'],
        email: row['Email'],
        phone: row['Phone'],
        address: row['Address'],
        notes: row['Notes']
      )
      if customer.valid?
        customer.save!
        @summary[:imported] += 1
        existing_emails << email
      else
        @errors << "Fila #{idx+2}: #{customer.errors.full_messages.join(', ')}"
        @summary[:failed] += 1
      end
    end

    @errors.empty?
  end
end 