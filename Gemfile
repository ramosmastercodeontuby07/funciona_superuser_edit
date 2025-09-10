# Gemfile
source "https://rubygems.org"

# (Opcional pero recomendado) fija tu versión de Ruby si la sabes:
# ruby "3.4.1"

gem "rails", "~> 8.0.2"
gem "puma", ">= 5.0"
gem "propshaft"

# Front-end Rails nativo
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Autenticación / Autorización
gem "bcrypt", "~> 3.1"
gem "pundit"

# ActiveStorage / imágenes
gem "image_processing", "~> 1.12"
gem "mini_magick"

# Export / hojas de cálculo / CSV
gem "caxlsx"
gem "caxlsx_rails"
gem "csv"

# Cache/Job/Cable (si los usas)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Opcionales de despliegue / servidor
gem "kamal", require: false
gem "thruster", require: false

# Windows no trae zoneinfo
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # Base de datos local (NO en producción)
  gem "sqlite3", ">= 2.1"

  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

group :production do
  # Base de datos en servidores (Render/Fly/Heroku/etc.)
  gem "pg", "~> 1.5"
end
