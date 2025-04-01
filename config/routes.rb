Rails.application.routes.draw do
  # Authentication routes
  devise_for :users
  
  # Dashboard route
  get 'dashboard', to: 'home#dashboard', as: 'dashboard'
  
  # Catalog routes
  resources :materials
  resources :units
  resources :manufacturing_processes
  resources :extras
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
      get :duplicate
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
        end
      end
      get 'extras', to: 'products#available_extras'
      get 'manufacturing_processes', to: 'products#available_manufacturing_processes'
      get 'materials', to: 'products#available_materials'
      get 'user_config', to: 'app_configs#user_config'
      get 'price_margins', to: 'price_margins#index'
      post 'search_customer', to: 'customers#search'
      get 'verify_pipedrive', to: 'customers#verify_pipedrive_account'
    end
  end
  
  # Application configs
  resource :app_configs, only: [:edit, :update] do
    collection do
      put :update_api_key
      get :test_facturama_api
      post :test_create_product
    end
  end
  
  # Defines the root path route ("/")
  root "home#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
