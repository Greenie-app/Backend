# frozen_string_literal: true

require File.expand_path("./environment", __dir__)

set :application, "greenie"
set :repo_url, "https://github.com/Greenie-app/Backend.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

set :pty, false

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/var/www/app.greenie.app"

append :linked_files, "config/master.key"

# Default value for linked_dirs is []
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets",
       "node_modules", "public/packs", "public/assets"

set :rvm_ruby_version, "3.2.1@#{fetch :application}"

set :sidekiq_config, "config/sidekiq.yml"

set :bugsnag_api_key, Rails.application.credentials.bugsnag_api_key

namespace :deploy do
  task :restart do
    on roles(:app) do
      sudo "systemctl", "restart", "rails-greenie"
    end
  end
end

namespace :sidekiq do
  task :restart do
    on roles(:app) do
      sudo "systemctl", "restart", "sidekiq-greenie"
    end
  end
end

after "deploy:finished", "deploy:restart"
after "deploy:finished", "sidekiq:restart"
