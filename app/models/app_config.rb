class AppConfig < ApplicationRecord
  belongs_to :user
  
  validates :key, presence: true
  validates :key, uniqueness: { scope: :user_id }
  
  # Define constants for keys to avoid typos
  # General settings
  WASTE_PERCENTAGE = 'waste_percentage'
  MARGIN_PERCENTAGE = 'margin_percentage'
  WIDTH_MARGIN = 'width_margin'
  LENGTH_MARGIN = 'length_margin'
  
  # Theme settings
  THEME_MODE = 'theme_mode'
  THEME_DARK = 'dark'
  THEME_LIGHT = 'light'
  
  # API Keys (stored in ENV but configured through app)
  PIPEDRIVE_API_KEY = 'pipedrive_api_key'
  
  # Sales conditions
  SALES_CONDITION_1 = 'sales_condition_1'
  SALES_CONDITION_2 = 'sales_condition_2'
  SALES_CONDITION_3 = 'sales_condition_3'
  SALES_CONDITION_4 = 'sales_condition_4'
  
  # Signature information
  SIGNATURE_NAME = 'signature_name'
  SIGNATURE_EMAIL = 'signature_email'
  SIGNATURE_PHONE = 'signature_phone'
  SIGNATURE_WHATSAPP = 'signature_whatsapp'
  
  # Value types
  TEXT = 'text'
  NUMERIC = 'numeric'
  PERCENTAGE = 'percentage'
  
  # Get typed value based on value_type
  def typed_value
    case value_type
    when NUMERIC
      value.to_f
    when PERCENTAGE
      value.to_f / 100.0
    else
      value
    end
  end
  
  # Class methods for getting/setting configs
  class << self
    # Get a config value for a user
    def get(user, key)
      config = user.app_configs.find_by(key: key)
      config&.typed_value
    end
    
    # Set a config value for a user
    def set(user, key, value, value_type = TEXT)
      config = user.app_configs.find_or_initialize_by(key: key)
      config.value = value
      config.value_type = value_type
      config.save
    end
    
    # Get all configs for a specific group (by prefix)
    def get_group(user, prefix)
      configs = user.app_configs.where('key LIKE ?', "#{prefix}%")
      configs.each_with_object({}) do |config, hash|
        hash[config.key] = config.typed_value
      end
    end
    
    # Get the Pipedrive API key
    def get_pipedrive_api_key
      # Simply find the first record with that key and return its value
      config = AppConfig.find_by(key: PIPEDRIVE_API_KEY)
      return config&.value
    end
  end
end 