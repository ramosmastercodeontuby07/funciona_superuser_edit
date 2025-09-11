source "https://rubygems.org"
# ruby "3.4.1"  # opcional si usas esa versión

gem "rails", "~> 8.0.2"
gem "puma", ">= 5.0"
gem "propshaft"
gem "bootsnap", require: false

# Front-end nativo Rails
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Auth/Autz
gem "bcrypt", "~> 3.1"
gem "pundit"

# ActiveStorage / imágenes
gem "image_processing", "~> 1.12"
gem "mini_magick"

# Export
gem "caxlsx"
gem "caxlsx_rails"
gem "csv"

# Cache/Job/Cable (si los usas)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "sqlite3", "~> 1.7"   # SOLO aquí, no en producción
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
  gem "pg", "~> 1.5"        # Postgres en producción
end
