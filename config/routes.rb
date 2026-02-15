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

  # Orders (S8 → S12)
  resources :orders, only: [ :new, :show, :update ] do
    member do
      get :filling       # S8: выбор наполнения
      patch :set_filling # S8: сохранить наполнение
      get :sku           # S9: выбор комплектации
      patch :set_sku     # S9: сохранить SKU
      get :checkout      # S10: форма оформления
      post :pay          # → redirect to YooKassa
      get :confirmed     # S12: заказ принят
    end
  end

  # YooKassa webhook
  post "payments/yookassa/webhook", to: "payments/webhooks#yookassa", as: :payments_yookassa_webhook

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
