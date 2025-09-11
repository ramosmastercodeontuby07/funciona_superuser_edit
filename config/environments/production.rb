# config/environments/production.rb
Rails.application.configure do
  # No recargar código en producción
  config.enable_reloading = false
  config.eager_load = true

  # No mostrar errores detallados
  config.consider_all_requests_local = false

  # Servir archivos estáticos (actívalo con RAILS_SERVE_STATIC_FILES=1)
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Fuerza HTTPS (puedes comentar esta línea si aún no tienes SSL)
  config.force_ssl = true

  # Permite el host de Render (y subdominios)
  config.hosts << ".onrender.com"

  # Cache en producción
  config.action_controller.perform_caching = true
  # Ejemplo de cache store (opcional; ajusta a Redis/Memcached si usas):
  # config.cache_store = :memory_store, { size: 64.megabytes }

  # Active Storage (ajusta si usas S3, etc.)
  # Usa env ACTIVE_STORAGE_SERVICE=s3, gcs, etc. Si no, local.
  config.active_storage.service = (ENV["ACTIVE_STORAGE_SERVICE"] || :local).to_sym

  # Mailer (ajusta si configuras SMTP real)
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = false

  # Logs
  config.log_level = :info
  config.log_tags  = [:request_id]
  config.active_support.report_deprecations = false

  # Formato/log a STDOUT (útil en Render)
  config.log_formatter = ::Logger::Formatter.new
  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # No volcar schema tras migraciones
  config.active_record.dump_schema_after_migration = false

  # (Opcional) Jobs con Solid Queue si lo usas:
  # config.active_job.queue_adapter = :solid_queue
end
