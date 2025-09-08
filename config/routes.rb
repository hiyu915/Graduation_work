Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  root "static_pages#top"

  resources :users do
    collection do
      get :edit_email       
      get :edit_email_form  
      post :request_email_change
      get :confirm_email_change
      get :account_info
    end
  end

  get "/activate/:id", to: "users#activate", as: :activate
  get "terms", to: "pages#terms", as: :terms

  resources :posts, only: %i[index new create show edit update destroy] do
    resource :favorite, only: [ :create, :destroy ]
    resource :visit, only: [ :create, :destroy ]
    collection do
      get :cities
      get :map
      get :calendar
    end
    member do
      delete :remove_image
      get :history
    end
  end

  resources :cities, only: [ :index ]
  resources :password_resets, only: %i[new create edit update]
  resource :account, only: [ :show, :destroy ], controller: "accounts"

  resources :contacts, only: [ :new, :create ] do
    collection do
      post :confirm
    end
  end

  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"

  get "privacy", to: "static_pages#privacy"
  get "rankings/regional", to: "rankings#regional"

  # --- 修正されたOAuthルート ---
  # OAuth共通コールバック（具体的なルートを先に配置）
  match "/oauth/callback", to: "oauths#callback", via: [:get, :post], as: :oauth_callback

  # OAuth認証開始（汎用的なルートを後に配置）
  get "/oauth/:provider", to: "oauths#oauth", as: :oauth  # ← 修正：oauth_index → oauth

  # Sorcery未完了OAuth用
  post "users/finish_oauth", to: "users#finish_oauth", as: :finish_oauth_users
end