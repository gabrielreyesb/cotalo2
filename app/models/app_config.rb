class AppConfig < ApplicationRecord
  belongs_to :user
  
  validates :key, presence: true
  validates :key, uniqueness: { scope: :user_id }
  
  # Define constants for keys to avoid typos
  # General settings
  WASTE_PERCENTAGE = 'waste_percentage'
  WIDTH_MARGIN = 'width_margin'
  LENGTH_MARGIN = 'length_margin'
  COMPANY_LOGO = 'company_logo'
  PRICE_ADJUSTMENT_PERCENTAGE = 'price_adjustment_percentage'
  THEME = 'theme'
  
  # API Keys (stored in ENV but configured through app)
  PIPEDRIVE_API_KEY = 'pipedrive_api_key'
  FACTURAMA_API_KEY = 'facturama_api_key'
  
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
      config.value = value.to_s
      config.value_type = value_type
      config.save
    end
    
    # Get all configs for a group (prefix)
    def get_group(user, prefix)
      configs = user.app_configs.where('key LIKE ?', "#{prefix}%")
      configs.each_with_object({}) do |config, hash|
        hash[config.key] = config.typed_value
      end
    end
    
    # Get Pipedrive API key (user-specific)
    def get_pipedrive_api_key(user)
      config = AppConfig.find_by(user_id: user.id, key: PIPEDRIVE_API_KEY)
      config&.value
    end
    
    # Get Facturama API key (user-specific)
    def get_facturama_api_key(user)
      config = AppConfig.find_by(user_id: user.id, key: FACTURAMA_API_KEY)
      config&.value
    end
  end
end 