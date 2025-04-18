class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :materials, dependent: :destroy
  has_many :manufacturing_processes, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_many :app_configs, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :price_margins

  after_create :setup_initial_data
  after_create :send_admin_notification

  def admin?
    admin
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
  
  # Get waste percentage (default 5%)
  def waste_percentage
    get_config(AppConfig::WASTE_PERCENTAGE) || 0.05
  end
  
  # Get width margin (default 0)
  def width_margin
    get_config(AppConfig::WIDTH_MARGIN) || 0
  end
  
  # Get length margin (default 0)
  def length_margin
    get_config(AppConfig::LENGTH_MARGIN) || 0
  end
  
  # Get sales conditions as an array
  def sales_conditions
    [
      get_config(AppConfig::SALES_CONDITION_1),
      get_config(AppConfig::SALES_CONDITION_2),
      get_config(AppConfig::SALES_CONDITION_3),
      get_config(AppConfig::SALES_CONDITION_4)
    ].compact
  end
  
  # Get signature information
  def signature_info
    {
      name: get_config(AppConfig::SIGNATURE_NAME) || '',
      email: get_config(AppConfig::SIGNATURE_EMAIL) || '',
      phone: get_config(AppConfig::SIGNATURE_PHONE) || '',
      whatsapp: get_config(AppConfig::SIGNATURE_WHATSAPP) || ''
    }
  end

  private

  def setup_initial_data
    # Set default waste percentage
    set_config(AppConfig::WASTE_PERCENTAGE, 0.05, AppConfig::PERCENTAGE)
    
    # Set default margins
    set_config(AppConfig::WIDTH_MARGIN, 0, AppConfig::NUMERIC)
    set_config(AppConfig::LENGTH_MARGIN, 0, AppConfig::NUMERIC)
  end

  def send_admin_notification
    AdminMailer.new_user_notification(self).deliver_later
  end
end
