# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  match "*path", via: :options, to: ->(_) { [204, {"Content-Type" => "text/plain"}] }

  if Rails.env.cypress?
    require "reset_cypress"
    require "cypress_emails"
    get "/cypress/reset" => ResetCypress.new
    get "/cypress/emails" => CypressEmails.new
  end

  devise_for :squadrons, skip: :all
  devise_scope :squadron do
    post "login" => "sessions#create"
    delete "logout" => "sessions#destroy"
    post "squadrons" => "registrations#create"
    delete "squadron" => "registrations#destroy"
    patch "squadron/password" => "registrations#update"
    put "squadron/password" => "registrations#update"
    get "registration/cancel" => "registrations#cancel"

    post "forgot_password" => "passwords#create"
    patch "forgot_password" => "passwords#update"
    put "forgot_password" => "passwords#update"
  end

  resources :squadrons, only: :show do
    resources :passes, only: %i[index show]
  end

  resource :squadron, only: :update do
    resources :logfiles, only: %i[index create]
    resources :pilots, only: %i[create update destroy] do
      member { post :merge }
    end
    resources :passes, only: %i[create update destroy] do
      collection { delete :unknown }
    end
  end

  if Rails.env.production?
    authenticate :squadron, -> { _1.admin? } do
      mount GoodJob::Engine => "good_job"
    end
  else
    mount GoodJob::Engine => "good_job"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root to: redirect(Rails.application.config.urls.frontend)

  # ensures proper reset-password link is generated by devise
  direct :edit_squadron_password do |args|
    URI.join(
      Rails.application.config.urls.frontend,
      "/#/reset_password/#{args[:reset_password_token]}"
    ).to_s
  end
end
