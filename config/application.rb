require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Greenie
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.generators do |g|
      g.test_framework :rspec, fixture: true, views: false
      g.integration_tool :rspec
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    # Use a real queuing backend for Active Job (and separate queues per environment).
    config.active_job.queue_adapter     = :sidekiq
    config.active_job.queue_name_prefix = "greenie_#{Rails.env}"

    config.urls = config_for(:urls)

    config.action_cable.url                     = config.urls.cable
    config.action_cable.allowed_request_origins = [config.urls.frontend]

    config.time_zone                      = 'UTC'
    config.active_record.default_timezone = :utc

    backend                                      = URI.parse(Rails.application.config.urls.backend)
    Rails.application.routes.default_url_options = {
        host:     backend.host,
        port:     backend.port,
        protocol: backend.scheme
    }
  end
end
