Rails.application.routes.draw do
  devise_for :users

  resources :studio_members, only: [:update]
  resources :game_projects, only: [:index, :show, :new, :create] do
    resources :rulebook_versions, only: [:create]
  end
  resources :rulebook_versions, only: [:show, :update] do
    post :publish, on: :member
    resources :playtest_sessions, only: [:create]
  end
  resources :playtest_sessions, only: [:update] do
    resources :feedbacks, only: [:create]
  end
  resources :feedbacks, only: [:index, :show, :update]
  get "escalations", to: "escalations#index"
  root "game_projects#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers or uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end