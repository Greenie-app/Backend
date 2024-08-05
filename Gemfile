# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.3.4"

# FRAMEWORK
gem "bootsnap"
gem "rack-cors"
gem "rails"
gem "sidekiq"

# MODELS
gem "active_storage_validations"
gem "image_processing"
gem "pg"

# CONTROLLERS
gem "responders"

# VIEWS
gem "jbuilder"
gem "redis"

# AUTH
gem "devise"
gem "devise-jwt"

# ERRORS
gem "bugsnag"

group :development do
  gem "listen"
  gem "puma"

  # DEVELOPMENT
  gem "binding_of_caller"
  gem "spring"
  gem "spring-watcher-listen"

  # DEPLOYMENT
  gem "dockerfile-rails"
end

group :test do
  # SPECS
  gem "boolean"
  gem "json_expressions"
  gem "json_matchers"
  gem "rails-controller-testing"
  gem "rspec-rails"

  # FACTORIES
  gem "factory_bot_rails"
  gem "ffaker"

  # ISOLATION
  gem "database_cleaner"
  gem "webmock"
end

group :doc do
  gem "redcarpet", require: nil
  gem "yard", require: nil
end

group :production do
  # STORAGE
  gem "aws-sdk-s3", require: false
end
