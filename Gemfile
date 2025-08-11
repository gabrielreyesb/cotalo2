source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.9"

# Rails core gems
gem "rails", "~> 7.1.0"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", ">= 1.4.4", require: false
gem "sqlite3", "~> 1.4"

# Asset pipeline
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "webpacker", "~> 5.4"
gem "sassc-rails"              # Para compilar Sass en producción

# Authentication and authorization
gem "devise"
gem "devise-i18n"

# File handling and processing
gem "roo", "~> 2.10"           # Para leer archivos Excel
gem "write_xlsx", "~> 0.85"    # Para escribir archivos Excel
gem "cloudinary"               # Para manejo de imágenes en la nube
gem "stripe"                   # Para pagos con Stripe
gem "prawn"                    # Para generar PDFs
gem "prawn-table"              # Para crear tablas en PDFs

# Geocoding and validation
gem "geocoder", "~> 1.8"       # Para geolocalización y validación de países

# Utilities
gem "colorize", "~> 0.8"       # Para output con colores en terminal
gem "kaminari"                 # Para paginación

# Environment variables
gem "dotenv-rails"

group :development, :test do
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
  gem "pry", "~> 0.14"         # Para debugging
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# and uncomment the following line if you're using Windows:
# gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Use Active Model has_secure_password
gem 'bcrypt', '~> 3.1.7'

# Use Down for downloading files from URLs
gem 'down', '~> 5.4'

# HTTP client
gem "httparty"                    # Para hacer requests HTTP a APIs externas

