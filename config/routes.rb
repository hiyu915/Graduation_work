Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  root "static_pages#top"

  resources :users, only: %i[new create]

  resources :posts, only: %i[index new create show edit update destroy] do
    resource :favorite, only: [ :create, :destroy ]
    resource :visit, only: [ :create, :destroy ]
    collection do
      get :cities
    end
    member do
      delete :remove_image
      get :history
    end
  end

  resources :cities, only: [ :index ]

  resources :password_resets, only: %i[new create edit update]

  get "login", to: "user_sessions#new"
  post "login", to: "user_sessions#create"
  delete "logout", to: "user_sessions#destroy"
end
