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

  # Generation passes (безлимит)
  resources :generation_passes, only: [:new, :create] do
    collection do
      get :limit_reached   # L1: экран "Лимит исчерпан"
    end
    member do
      get :confirmed       # после оплаты
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

  # Admin
  namespace :admin do
    root "dashboard#index"
    resources :tags, except: :show do
      collection do
        post :import_csv
      end
      member do
        post :merge
      end
      resources :synonyms, only: [:create, :destroy], controller: "tag_synonyms"
    end
    resources :styles, except: :show do
      member do
        patch :publish
        patch :hide
      end
    end
    resources :orders, only: [:index, :show] do
      member do
        patch :change_status
      end
      collection do
        get :export_csv
      end
    end
    resources :settings, only: [:index, :update], param: :key
    resources :audit_logs, only: [:index]
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq Web UI (admin only, mounted in production behind auth)
  # require "sidekiq/web"
  # mount Sidekiq::Web => "/sidekiq"
end
