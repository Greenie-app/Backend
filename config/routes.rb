Rails.application.routes.draw do
  match '*path', via: :options, to: ->(_) { [204, {'Content-Type' => 'text/plain'}] }

  require 'sidekiq/web'
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(Rails.application.credentials.sidekiq_web[:user])) &
        ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(Rails.application.credentials.sidekiq_web[:password]))
  end
  mount Sidekiq::Web, at: '/sidekiq'

  if Rails.env.cypress?
    require 'reset_cypress'
    require 'cypress_emails'
    get '/cypress/reset' => ResetCypress.new
    get '/cypress/emails' => CypressEmails.new
  end

  if Rails.env.production?
    mount ActionCable.server => '/cable'
  end

  devise_for :squadrons, skip: :all
  devise_scope :squadron do
    post 'login' => 'sessions#create'
    delete 'logout' => 'sessions#destroy'
    post 'squadrons' => 'registrations#create'
    delete 'squadron' => 'registrations#destroy'
    patch 'squadron/password' => 'registrations#update'
    put 'squadron/password' => 'registrations#update'
    get 'registration/cancel' => 'registrations#cancel'

    post 'forgot_password' => 'devise/passwords#create'
    patch 'forgot_password' => 'devise/passwords#update'
    put 'forgot_password' => 'devise/passwords#update'
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

  root to: redirect(Rails.application.config.urls.frontend)

  direct :edit_squadron_password do |args|
    URI.join(
        Rails.application.config.urls.frontend,
        '/#/reset_password/' + args[:reset_password_token]
    ).to_s
  end
end
