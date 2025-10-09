# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.4.6"

# FRAMEWORK
gem "bootsnap"
gem "good_job"
gem "puma"
gem "rack-cors"
gem "rails"

# MODELS
gem "active_storage_validations"
gem "image_processing"
gem "pg"

# CONTROLLERS
gem "responders"

# VIEWS
gem "jbuilder"
gem "kredis"
gem "redis"

# AUTH
gem "devise"
gem "devise-jwt"

# ACTION CABLE
gem "anycable-rails"

# ERRORS
gem "sentry-rails"
gem "sentry-ruby"

group :development do
  gem "listen"

  # LINTING
  gem "brakeman", require: false

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
  gem "database_cleaner-active_record"
  gem "webmock"
end

group :doc do
  gem "redcarpet", require: false
  gem "yard", require: false
end

group :production do
  # STORAGE
  gem "aws-sdk-s3", require: false
end
