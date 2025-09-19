# Gemfile
source "https://rubygems.org"

# (Opcional) si usas .ruby-version:
# ruby "3.4.1"

# --- Core / servidor / assets ---
gem "rails", "~> 8.0.2"
gem "puma", ">= 5.0"
gem "propshaft"
gem "bootsnap", require: false

# --- Front-end Rails nativo ---
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# --- Autenticación / Autorización ---
gem "bcrypt", "~> 3.1"
gem "pundit"

# --- Archivos / imágenes ---
gem "image_processing", "~> 1.12"
gem "mini_magick"

# --- Exportaciones ---
gem "caxlsx"
gem "caxlsx_rails"
gem "csv"

# --- Cache / Jobs / Cable (Rails 8) ---
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# --- Despliegue opcional ---
gem "kamal", require: false
gem "thruster", require: false

# Windows / JRuby
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  # Rails 8 requiere sqlite3 >= 2.1 cuando usas SQLite
  gem "sqlite3", "~> 2.7"

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
  # Base de datos en servidor (Render/Fly/Heroku)
  gem "pg", "~> 1.5"
end
