Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Authentication routes
  devise_for :users
  
  # Dashboard route
  get 'dashboard', to: 'home#dashboard', as: 'dashboard'
  
  # Catalog routes
  resources :materials
  resources :units
  resources :manufacturing_processes
  resources :extras
  
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
      post 'search_customer', to: 'customers#search'
      get 'verify_pipedrive', to: 'customers#verify_pipedrive_account'
    end
  end
  
  # Application configs
  resource :app_configs, only: [:edit, :update] do
    put :update_api_key, on: :collection
  end
  
  # Defines the root path route ("/")
  root "home#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
