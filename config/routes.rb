Rails.application.routes.draw do
  # OmniAuth callbacks
  get  "auth/:provider/callback", to: "sessions#create"
  post "auth/:provider/callback", to: "sessions#create"
  get  "auth/failure",            to: "sessions#failure"
  delete "logout",                to: "sessions#destroy", as: :logout

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq Web UI (admin only, mounted in production behind auth)
  # require "sidekiq/web"
  # mount Sidekiq::Web => "/sidekiq"
end
