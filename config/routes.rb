Rails.application.routes.draw do
  get 'demo_requests/new'
  get 'demo_requests/create'
  # Authentication routes
  devise_for :users
  
  # Admin routes
  namespace :admin do
    root to: 'dashboard#index'
    resources :users do
      member do
        post :toggle_disabled
      end
    end
    resources :impersonations, only: [:create]
    delete 'impersonations', to: 'impersonations#destroy', as: :impersonations_destroy
    resources :units
    resources :news do
      member do
        post :send_email
      end
    end
    resources :suggestions, only: [:index, :update]
    resources :trial_management, only: [:index] do
      collection do
        post :bulk_extend_trial
      end
      member do
        post :extend_trial
        post :reset_trial
        post :disable_trial
      end
    end
  end
  
  # Dashboard route
  get 'dashboard', to: 'home#dashboard', as: 'dashboard'
  post 'dashboard/close_block', to: 'home#close_block', as: 'close_dashboard_block'
  post 'close_block', to: 'home#close_block', as: 'close_block'
  
  # News routes
  resources :news
  
  # Catalog routes
  resources :materials do
    member do
      post :duplicate
    end
  end
  resources :manufacturing_processes do
    member do
      post :duplicate
    end
  end
  resources :extras do
    member do
      post :duplicate
    end
  end
  scope '/catalog' do
    resources :price_margins do
      collection do
        get :calculate
      end
    end
  end
  
  # Product routes with duplicate action
  resources :products do
    member do
      post :duplicate
      get :general_info
      get :pricing
      get :modal_test
    end
    
    collection do
      get :materials_list
      get :processes_list
      get :extras_list
    end
  end
  
  # Quote routes with product management actions
  resources :quotes do
    member do
      post :add_product
      delete :remove_product
      patch :update_product_quantity
      get :pdf
      get :modern_pdf
      get :duplicate
      post :send_email
    end
    
    collection do
      post :search_customer
    end
    
    # Nested invoices resources
    resources :invoices, only: [:create, :show] do
      member do
        get :status
      end
    end
  end
  
  # API routes
  namespace :api do
    namespace :v1 do
      resources :products, only: [:show, :update, :create] do
        member do
          get :extras
          put :update_extras
          put :update_extras_comments
          put :update_processes
          put :update_processes_comments
          put :update_materials
          put :update_materials_comments
          put :update_pricing
          put :update_selected_material
          put :update_include_extras_in_subtotal
        end
      end
      get 'extras', to: 'products#available_extras'
      get 'manufacturing_processes', to: 'products#available_manufacturing_processes'
      get 'materials', to: 'products#available_materials'
      get 'user_config', to: 'app_configs#user_config'
      get 'price_margins', to: 'price_margins#index'
      get 'price_margins/calculate', to: 'price_margins#calculate'
      post 'search_customer', to: 'customers#search'
      get 'verify_pipedrive', to: 'customers#verify_pipedrive_account'
    end
  end
  
  # Application configs
  resource :app_configs, only: [:edit, :update] do
    collection do
      post :update_api_key
      post :test_facturama_api
      post :update_logo
    end
  end
  
  # Price adjustments
  resource :price_adjustments, only: [:edit] do
    collection do
      post :update_prices
    end
  end
  
  # PDF config
  resource :pdf_config, only: [:edit, :update] do
    post :update_logo, on: :collection
  end
  
  # Simple admin route
  get 'admin', to: 'admin#index'
  
  # Defines the root path route ("/")
  root "home#index"
  
  # About Us page
  get 'about', to: 'home#about', as: :about

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :suggestions, only: [:index, :create, :edit, :update]

  # Stripe webhook endpoint
  post 'stripe/webhook', to: 'stripe_webhooks#create'

  # Subscription routes
  resource :subscription, only: [:new, :create, :show, :update, :destroy] do
    collection do
      get 'subscribe', to: 'subscriptions#new', as: :subscribe
      post 'create_checkout_session', to: 'subscriptions#create_checkout_session'
    end
  end

  # Customers import-related routes (move these above resources :customers)
  get 'customers/import', to: 'customers#import', as: :import_customers
  post 'customers/validate_upload', to: 'customers#validate_upload', as: :validate_upload_customers
  post 'customers/import_process', to: 'customers#import_process', as: :import_process_customers
  get 'customers/import_template', to: 'customers#import_template', as: :import_template_customers
  delete 'customers/clear_import_session', to: 'customers#clear_import_session', as: :clear_import_session_customers

  resources :customers

  # Demo requests
  resources :demo_requests, only: [:new, :create]
  get 'demo_request/success', to: 'demo_requests#success', as: :demo_request_success
end
