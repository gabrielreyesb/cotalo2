class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :materials, dependent: :destroy
  has_many :units, dependent: :destroy
  has_many :manufacturing_processes, dependent: :destroy
  has_many :extras, dependent: :destroy
  has_many :app_configs, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :price_margins

  after_create :setup_initial_data

  def admin?
    # Change this to match your authentication system's way of determining admins
    # This is a placeholder implementation
    # For example, you might have an 'admin' boolean column, or a role-based system
    admin_emails = ['gabrielreyesb@gmail.com'] # Add your admin emails here
    admin_emails.include?(email)
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
  
  # Get margin percentage (default 30%)
  def margin_percentage
    get_config(AppConfig::MARGIN_PERCENTAGE) || 0.3
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
    name = get_config(AppConfig::SIGNATURE_NAME)
    email = get_config(AppConfig::SIGNATURE_EMAIL)
    phone = get_config(AppConfig::SIGNATURE_PHONE)
    whatsapp = get_config(AppConfig::SIGNATURE_WHATSAPP)
    
    # If name is missing, use a default
    name = "Jonathan Gabriel Rubio Huerta" if name.blank?
    
    {
      name: name,
      email: email,
      phone: phone,
      whatsapp: whatsapp
    }
  end

  private

  def setup_initial_data
    # Setup default configuration values
    set_config(AppConfig::WASTE_PERCENTAGE, 5, AppConfig::PERCENTAGE)
    set_config(AppConfig::MARGIN_PERCENTAGE, 30, AppConfig::PERCENTAGE)
    set_config(AppConfig::WIDTH_MARGIN, 0, AppConfig::NUMERIC)
    set_config(AppConfig::LENGTH_MARGIN, 0, AppConfig::NUMERIC)
    
    # Default sales conditions
    set_config(AppConfig::SALES_CONDITION_1, "50% de anticipo para iniciar el trabajo")
    set_config(AppConfig::SALES_CONDITION_2, "50% al entregar")
    set_config(AppConfig::SALES_CONDITION_3, "Precios más IVA")
    set_config(AppConfig::SALES_CONDITION_4, "Precios sujetos a cambio sin previo aviso")
    
    # Default signature information
    set_config(AppConfig::SIGNATURE_NAME, "Jonathan Gabriel Rubio Huerta")
    set_config(AppConfig::SIGNATURE_EMAIL, "jonathanrubio@surtibox.com")
    set_config(AppConfig::SIGNATURE_PHONE, "3311764022 / 33 2484 9954")
    set_config(AppConfig::SIGNATURE_WHATSAPP, "3311764022")
    
    # Add any other initial data setup here
  end
end
