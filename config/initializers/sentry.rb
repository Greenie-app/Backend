# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.dsn                = ENV.fetch("SENTRY_DSN", nil)

  config.send_default_pii = true

  config.enable_logs = true
  config.enabled_patches = %i[logger]

  config.traces_sample_rate = 1.0
  config.profiles_sample_rate = 1.0
end
