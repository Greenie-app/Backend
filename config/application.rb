# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Greenie
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

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
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    # Use a real queuing backend for Active Job (and separate queues per environment).
    config.active_job.queue_name_prefix = "greenie_#{Rails.env}"

    config.urls = config_for(:urls)

    config.action_cable.url                     = config.urls.cable
    config.action_cable.allowed_request_origins = [config.urls.frontend]

    config.time_zone                      = "UTC"
    config.active_record.default_timezone = :utc

    config.active_record.encryption.support_sha1_for_non_deterministic_encryption = false

    backend                                      = URI.parse(Rails.application.config.urls.backend)
    Rails.application.routes.default_url_options = {
        host:     backend.host,
        port:     backend.port,
        protocol: backend.scheme
    }

    # for GoodJob dashboard
    config.middleware.use Rack::MethodOverride
    config.middleware.use ActionDispatch::Flash
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    config.active_job.queue_adapter          = :good_job
    config.good_job.max_threads              = 2
    config.good_job.poll_interval            = 30 # seconds
    config.good_job.enable_cron              = true
    config.good_job.dashboard_default_locale = :en
    config.good_job.queues                   = "greenie_#{Rails.env}_default"

    config.host_authorization = {exclude: ->(request) { request.path.start_with?("/up") }}
  end
end
