Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  root "static_pages#top"

  resources :users do
    collection do
      get :edit_email
      post :request_email_change
      get :confirm_email_change
      get :account_info
    end
  end

  get "/activate/:id", to: "users#activate", as: :activate

  get "terms", to: "pages#terms", as: :terms

  get "help", to: "static_pages#help", as: :help
  get "news", to: "static_pages#news", as: :news
  get "faq",  to: "static_pages#faq",  as: :faq

  resources :posts, only: %i[index new create show edit update destroy] do
    resource :favorite, only: [ :create, :destroy ]
    resource :visit, only: [ :create, :destroy ]
    collection do
      get :cities
      get :map
      get :calendar
      get :autocomplete
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

  namespace :api do
    namespace :v1 do
      resources :posts
    end
  end

  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"

  get "privacy", to: "static_pages#privacy"

  get "rankings/regional", to: "rankings#regional"

  post "oauth/callback" => "oauths#callback"
  get "oauth/callback" => "oauths#callback"
  get "oauth/:provider" => "oauths#oauth", :as => :auth_at_provider
end
