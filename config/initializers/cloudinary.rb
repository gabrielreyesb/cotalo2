require 'cloudinary'
require 'cloudinary/uploader'
require 'cloudinary/utils'

# Configure Cloudinary with environment variables
Cloudinary.config do |config|
  config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
  config.api_key = ENV['CLOUDINARY_API_KEY']
  config.api_secret = ENV['CLOUDINARY_API_SECRET']
  config.secure = true
end

# Log configuration for debugging
Rails.logger.info "Cloudinary Configuration:"
Rails.logger.info "Cloud name: #{Cloudinary.config.cloud_name}"
Rails.logger.info "API key present: #{Cloudinary.config.api_key.present?}"
Rails.logger.info "API secret present: #{Cloudinary.config.api_secret.present?}" 