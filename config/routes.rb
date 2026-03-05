Rails.application.routes.draw do
  resources :topics, only: [ :index, :show, :new, :create ], param: :slug do
    resources :citation_events, only: [ :new, :create ]
    post :synthesize, on: :member
  end
  get "/rubric", to: "rubric#index"
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root
  root "home#index"

  # AT Protocol OAuth
  post "/auth/bluesky/start", to: "sessions#start", as: :start_bluesky_auth
  get  "/auth/atproto/callback", to: "sessions#callback"
  get  "/auth/failure", to: "sessions#failure"
  get  "/oauth/client-metadata.json", to: "sessions#client_metadata", as: :client_metadata
  delete "/logout", to: "sessions#destroy", as: :logout

  # PDS write test
  post "/test_post", to: "home#test_post", as: :test_post
end
