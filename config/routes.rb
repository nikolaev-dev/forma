Rails.application.routes.draw do
  # OmniAuth callbacks
  get  "auth/:provider/callback", to: "sessions#create"
  post "auth/:provider/callback", to: "sessions#create"
  get  "auth/failure",            to: "sessions#failure"
  delete "logout",                to: "sessions#destroy", as: :logout

  # Pages
  root "catalog#index"
  get "catalog", to: "catalog#index"

  resources :creations, only: [ :new, :create, :show ] do
    member do
      get :progress
      get :result
    end
  end

  # API
  namespace :api do
    get "catalog/styles",   to: "catalog#styles"
    get "catalog/sections", to: "catalog#sections"
    get "tags/search",      to: "tags#search"
    get "generations/:id/status", to: "generations#status", as: :generation_status
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq Web UI (admin only, mounted in production behind auth)
  # require "sidekiq/web"
  # mount Sidekiq::Web => "/sidekiq"
end
