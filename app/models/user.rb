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
  has_many :price_margins
  has_many :suggestions

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
  # def trial?
  #   subscription_status == SUBSCRIPTION_STATUS_TRIAL
  # end

  # def active_subscription?
  #   subscription_status == SUBSCRIPTION_STATUS_ACTIVE
  # end

  # def subscription_active?
  #   return true if trial? && trial_ends_at > Time.current
  #   return true if active_subscription? && subscription_ends_at > Time.current
  #   false
  # end

  # def trial_days_remaining
  #   return 0 unless trial?
  #   return 0 if trial_ends_at.nil?
  #   [(trial_ends_at - Time.current).to_i / 1.day, 0].max
  # end

  # def subscription_days_remaining
  #   return 0 unless active_subscription?
  #   return 0 if subscription_ends_at.nil?
  #   [(subscription_ends_at - Time.current).to_i / 1.day, 0].max
  # end

  # def trial_percentage_completed
  #   return 0 unless trial?
  #   return 0 if trial_ends_at.nil?
  #   total_days = TRIAL_PERIOD_DAYS
  #   days_used = total_days - trial_days_remaining
  #   (days_used.to_f / total_days * 100).round(2)
  # end

  def setup_trial_period
    return unless trial_ends_at.nil?
    update(
      trial_ends_at: TRIAL_PERIOD_DAYS.days.from_now,
      subscription_status: SUBSCRIPTION_STATUS_TRIAL
    )
  end

  private

  def setup_initial_data
    setup_trial_period
    begin
      Rails.logger.info "[setup_initial_data] Creating or finding units..."
      mt2_unit = Unit.find_or_create_by!(name: 'mt2')
      mt2_unit.update!(abbreviation: 'm²') unless mt2_unit.abbreviation == 'm²'
      pieza_unit = Unit.find_or_create_by!(name: 'pieza')
      pieza_unit.update!(abbreviation: 'pieza') unless pieza_unit.abbreviation == 'pieza'
      pliego_unit = Unit.find_or_create_by!(name: 'pliego')
      pliego_unit.update!(abbreviation: 'pliego') unless pliego_unit.abbreviation == 'pliego'
      Rails.logger.info "[setup_initial_data] Units: mt2=#{mt2_unit.id}, pieza=#{pieza_unit.id}, pliego=#{pliego_unit.id}"

      Rails.logger.info "[setup_initial_data] Setting default app configs..."
      set_config(AppConfig::WASTE_PERCENTAGE, 10, AppConfig::PERCENTAGE)
      set_config(AppConfig::WIDTH_MARGIN, 2, AppConfig::NUMERIC)
      set_config(AppConfig::LENGTH_MARGIN, 2, AppConfig::NUMERIC)

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
      Rails.logger.info "[setup_initial_data] Demo data creation complete."
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
