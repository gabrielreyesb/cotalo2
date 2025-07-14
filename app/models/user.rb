class User < ApplicationRecord
  include StripeSubscription

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  has_many :materials, dependent: :destroy
  has_many :manufacturing_processes, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_many :app_configs, dependent: :destroy
  has_one :pdf_config, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :price_margins, dependent: :destroy
  has_many :suggestions, dependent: :destroy
  has_many :customers, dependent: :destroy

  after_create :setup_initial_data
  after_create :send_admin_notification
  after_create :send_welcome_email

  # Subscription status constants
  SUBSCRIPTION_STATUS_TRIAL = 'trial'
  SUBSCRIPTION_STATUS_ACTIVE = 'active'
  SUBSCRIPTION_STATUS_PAST_DUE = 'past_due'
  SUBSCRIPTION_STATUS_CANCELLED = 'cancelled'
  SUBSCRIPTION_STATUS_EXPIRED = 'expired'

  # Trial period in days
  TRIAL_PERIOD_DAYS = 14

  # Set default subscription status for new users
  after_initialize :set_default_subscription_status, if: :new_record?

  def admin?
    admin
  end

  def disabled?
    disabled
  end

  def active_for_authentication?
    return true if admin? # Allow admins to always be active
    super && !disabled? && subscription_active?
  end

  def inactive_message
    if disabled?
      :account_disabled
    elsif !subscription_active?
      if trial?
        :trial_expired
      else
        :subscription_expired
      end
    else
      super
    end
  end

  # Helper methods to access configuration values
  
  # Get a configuration value
  def get_config(key)
    AppConfig.get(self, key)
  end
  
  # Set a configuration value
  def set_config(key, value, value_type = AppConfig::TEXT)
    AppConfig.set(self, key, value, value_type)
  end
  
  # Get waste percentage (default 0) – returns the numeric value as stored (e.g. 10 for 10%)
  def waste_percentage
    get_config(AppConfig::WASTE_PERCENTAGE) || 0
  end
  
  # (Optional) Get waste percentage as a decimal (e.g. 0.1 for 10%)
  def waste_percentage_decimal
    (get_config(AppConfig::WASTE_PERCENTAGE) || 0) / 100.0
  end
  
  # Get width margin (default 0)
  def width_margin
    get_config(AppConfig::WIDTH_MARGIN) || 0
  end
  
  # Get length margin (default 0)
  def length_margin
    get_config(AppConfig::LENGTH_MARGIN) || 0
  end

  # Subscription-related methods
  def trial?
    subscription_status == SUBSCRIPTION_STATUS_TRIAL
  end

  def active_subscription?
    subscription_status == SUBSCRIPTION_STATUS_ACTIVE
  end

  def subscription_active?
    return true if trial? && trial_ends_at.present? && trial_ends_at > Time.current
    return true if active_subscription? && subscription_ends_at.present? && subscription_ends_at > Time.current
    false
  end

  def trial_days_remaining
    return 0 unless trial?
    return 0 if trial_ends_at.nil?
    [(trial_ends_at - Time.current).to_i / 1.day, 0].max
  end

  def subscription_days_remaining
    return 0 unless active_subscription?
    return 0 if subscription_ends_at.nil?
    [(subscription_ends_at - Time.current).to_i / 1.day, 0].max
  end

  def trial_percentage_completed
    return 0 unless trial?
    return 0 if trial_ends_at.nil?
    total_days = TRIAL_PERIOD_DAYS
    days_used = total_days - trial_days_remaining
    (days_used.to_f / total_days * 100).round(2)
  end

  def setup_trial_period
    return unless trial_ends_at.nil?
    update(
      trial_ends_at: TRIAL_PERIOD_DAYS.days.from_now,
      subscription_status: SUBSCRIPTION_STATUS_TRIAL
    )
  end

  def example_product
    products.find_by(description: "Producto de prueba")
  end

  def dashboard_preferences
    JSON.parse(self[:dashboard_preferences] || '{}')
  rescue JSON::ParserError
    {}
  end

  def dashboard_preferences=(preferences)
    self[:dashboard_preferences] = preferences.to_json
  end

  def block_closed?(block_name)
    dashboard_preferences[block_name.to_s] == true
  end

  def close_block(block_name)
    prefs = dashboard_preferences
    prefs[block_name.to_s] = true
    self.dashboard_preferences = prefs
    save
  end

  private

  def setup_initial_data
    setup_trial_period
    begin
      Rails.logger.info "[setup_initial_data] Creating or finding units..."
      mt2_unit = Unit.find_or_create_by!(name: 'mt2', abbreviation: 'm²')
      pieza_unit = Unit.find_or_create_by!(name: 'pieza', abbreviation: 'pieza')
      pliego_unit = Unit.find_or_create_by!(name: 'pliego', abbreviation: 'pliego')

      Rails.logger.info "[setup_initial_data] Setting default app configs..."
      set_config(AppConfig::WASTE_PERCENTAGE, 0, AppConfig::PERCENTAGE)
      set_config(AppConfig::WIDTH_MARGIN, 0, AppConfig::NUMERIC)
      set_config(AppConfig::LENGTH_MARGIN, 0, AppConfig::NUMERIC)

      Rails.logger.info "[setup_initial_data] Creating demo materials..."
      materials.create!([
        { description: 'Caple 12 puntos', client_description: 'Caple', price: 10, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Cartulina multicapa 14 pts', client_description: 'Cartulina multicapa', price: 12, unit: mt2_unit, ancho: 100, largo: 100 },
        { description: 'Liner Kraft 180 gramos', client_description: 'Liner Kraft', price: 6, unit: mt2_unit, ancho: 100, largo: 100 }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo manufacturing processes..."
      manufacturing_processes.create!([
        { name: 'Empalmado', description: '', cost: 3.50, unit: mt2_unit },
        { name: 'Pegado lineal', description: '', cost: 0.35, unit: pieza_unit },
        { name: 'Impresión flexográfica', description: '', cost: 1.20, unit: pliego_unit }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo extras..."
      extras.create!([
        { name: 'Placas de impresión 4 oficios', description: '', cost: 250, unit: pieza_unit },
        { name: 'Suaje plano', description: '', cost: 2950, unit: pieza_unit }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo price margins..."
      price_margins.create!([
        { min_price: 0, max_price: 5000, margin_percentage: 10 },
        { min_price: 5001, max_price: 50000, margin_percentage: 15 },
        { min_price: 50001, max_price: 200000, margin_percentage: 25 }
      ])

      Rails.logger.info "[setup_initial_data] Creating demo product..."
      # Get the created demo data
      demo_materials = materials.limit(3).to_a
      demo_processes = manufacturing_processes.limit(3).to_a
      demo_extras = extras.limit(2).to_a

      # Create a test product with 2 materials, 2 processes, and 1 extra
      test_product = products.create!(
        description: "Producto de prueba",
        data: {
          general_info: {
            width: 50,
            length: 30,
            inner_measurements: nil,
            quantity: 100,
            comments: "Producto de demostración para nuevos usuarios"
          },
          materials: [
            {
              material_id: demo_materials[0].id,
              description: demo_materials[0].description,
              client_description: demo_materials[0].client_description,
              resistance: demo_materials[0].resistance,
              price: demo_materials[0].price,
              unit: {
                id: demo_materials[0].unit.id,
                name: demo_materials[0].unit.name,
                abbreviation: demo_materials[0].unit.abbreviation
              },
              ancho: demo_materials[0].ancho,
              largo: demo_materials[0].largo,
              quantity: 100,
              piecesPerMaterial: 6,
              totalSheets: 17,
              totalSquareMeters: 17.0,
              totalPrice: 170.0,
              comments: "Material principal del producto"
            },
            {
              material_id: demo_materials[1].id,
              description: demo_materials[1].description,
              client_description: demo_materials[1].client_description,
              resistance: demo_materials[1].resistance,
              price: demo_materials[1].price,
              unit: {
                id: demo_materials[1].unit.id,
                name: demo_materials[1].unit.name,
                abbreviation: demo_materials[1].unit.abbreviation
              },
              ancho: demo_materials[1].ancho,
              largo: demo_materials[1].largo,
              quantity: 100,
              piecesPerMaterial: 6,
              totalSheets: 17,
              totalSquareMeters: 17.0,
              totalPrice: 204.0,
              comments: "Material secundario para detalles"
            }
          ],
          processes: [
            {
              id: demo_processes[0].id,
              description: demo_processes[0].name,
              unit: demo_processes[0].unit.abbreviation,
              unitPrice: demo_processes[0].cost,
              materialId: demo_materials[0].id,
              materialDescription: demo_materials[0].description,
              price: 3.5 * 17.0,
              quantity: 17.0,
              comments: "Proceso principal de empalmado"
            },
            {
              id: demo_processes[1].id,
              description: demo_processes[1].name,
              unit: demo_processes[1].unit.abbreviation,
              unitPrice: demo_processes[1].cost,
              materialId: demo_materials[1].id,
              materialDescription: demo_materials[1].description,
              price: 0.35 * 100,
              quantity: 100,
              comments: "Pegado lineal para cada pieza"
            }
          ],
          extras: [
            {
              id: demo_extras[0].id,
              name: demo_extras[0].name,
              description: demo_extras[0].description,
              unit_price: demo_extras[0].cost.to_f,
              quantity: 1,
              total: demo_extras[0].cost.to_f * 1,
              comments: "Placas necesarias para la impresión"
            }
          ],
          pricing: {
            materials_cost: 374.0,
            processes_cost: 94.5,
            extras_cost: 250.0,
            subtotal: 718.5,
            waste_percentage: 5,
            waste_value: 35.93,
            price_per_piece_before_margin: 7.54,
            margin_percentage: 10,
            margin_value: 75.44,
            total_price: 829.87,
            final_price_per_piece: 8.30
          }
        }
      )

      Rails.logger.info "[setup_initial_data] Demo data creation complete."
      
      # Create a test quote using the test product
      Rails.logger.info "[setup_initial_data] Creating demo quote..."
      test_quote = quotes.create!(
        project_name: "Proyecto de demostración",
        customer_name: "Cliente de prueba",
        organization: "Empresa de demostración",
        email: "cliente@ejemplo.com",
        telephone: "555-123-4567",
        comments: "Cotización de demostración para nuevos usuarios",
        data: Quote.default_data
      )
      
      # Add the test product to the quote
      test_quote.quote_products.create!(
        product: test_product,
        quantity: 50
      )
      
      # Calculate totals for the quote
      test_quote.calculate_totals
      
      Rails.logger.info "[setup_initial_data] Demo quote created: #{test_quote.quote_number}"
    rescue => e
      Rails.logger.error "[setup_initial_data] ERROR: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  def send_admin_notification
    AdminMailer.new_user_notification(self).deliver_later
  end

  def send_welcome_email
    UserMailer.welcome_email(self).deliver_later
  end

  def set_default_subscription_status
    self.subscription_status ||= 'trial'
  end
end
