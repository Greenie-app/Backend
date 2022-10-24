# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

ActiveSupport::Reloader.to_prepare do
  backend = URI.parse(Rails.application.config.urls.backend)
  ApplicationController.renderer.defaults.merge! http_host: backend.host,
                                                 port:      backend.port,
                                                 https:     backend.scheme == "https"
end
