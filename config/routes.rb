require "sidekiq/web"
require "sidekiq-cron"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # ---- Auth --------------------------------------------------
  devise_for :users, path: "",
    path_names: { sign_in: "entrar", sign_out: "sair", sign_up: "cadastro" },
    controllers: {
      sessions:           "auth/sessions",
      registrations:      "auth/registrations",
      omniauth_callbacks: "auth/omniauth_callbacks"
    }

  # ---- Área pública ------------------------------------------
  root "pages#home"
  get "sobre",   to: "pages#about",   as: :about
  get "contato", to: "pages#contact", as: :contact
  get "termos",  to: "pages#terms",   as: :terms

  # ---- Perfil do usuário ------------------------------------
  resource :perfil, only: [:edit, :update], controller: "users/profiles",
    path_names: { edit: "editar" }

  # Completar cadastro (ex.: após login com Google)
  resource :completar_cadastro, only: [:show, :update],
    controller: "users/profile_completions", path: "completar-cadastro",
    as: :profile_completion

  resource :carteira, only: [:show], controller: "users/wallets"
  resources :recargas, only: [:create], controller: "users/credit_purchases"

  # ---- Agendamento ------------------------------------------
  scope module: "scheduling" do
    resource :carrinho, only: [:show, :destroy], path: "carrinho",
      controller: "carts" do
      post   "adicionar/:availability_id", to: "carts#add",    as: :add_to
      delete "remover/:availability_id",   to: "carts#remove", as: :remove_from
    end

    resources :reservas, only: [:index, :show], controller: "bookings" do
      collection do
        get  "confirmar", to: "bookings#new"
        post "confirmar", to: "bookings#create"
      end
      member do
        patch "cancelar", to: "bookings#cancel"
      end
    end
  end

  # ---- Pagamentos -------------------------------------------
  scope module: "payments" do
    resources :pagamentos, only: [:show], path: "pagamento",
      controller: "payments" do
      member do
        get  "aguardando", to: "payments#pending"
        post "cancelar",   to: "payments#cancel"
      end
    end

    # Retorno após pagamento no InfinitePay
    get "pagamento/retorno", to: "payments#return", as: :retorno_pagamento

    post "webhooks/infinitepay", to: "webhooks#infinitepay",
      as: :infinitepay_webhook
  end

  # ---- Painel Admin -----------------------------------------
  namespace :admin do
    root to: "dashboard#index"

    # Integração Google Agenda (owner conecta a própria agenda)
    get    "google_calendar/connect",  to: "google_calendar#connect",    as: :connect_google_calendar
    get    "google_calendar/callback", to: "google_calendar#callback",   as: :callback_google_calendar
    delete "google_calendar",          to: "google_calendar#disconnect", as: :google_calendar

    resources :clinics,        only: [:show, :update]
    resources :users, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
      member do
        post   :add_credit
        delete :remove_credit
      end
    end
    resources :services,       except: [:show]
    resources :availabilities, except: [:show] do
      member { patch :toggle }
    end
    resources :discount_rules, except: [:show]
    resources :bookings,       only: [:index, :show, :create] do
      member do
        patch "cancelar",      action: :cancel
        patch "alterar-turno", action: :change_slot, as: :change_slot
      end
    end
    resources :payments, only: [:index, :show]
    resources :credits,  only: [:index]

    authenticate :user, ->(u) { u.owner? } do
      mount Sidekiq::Web => "/sidekiq"
    end
  end

  # ---- PWA --------------------------------------------------
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest"       => "rails/pwa#manifest",       as: :pwa_manifest
end
