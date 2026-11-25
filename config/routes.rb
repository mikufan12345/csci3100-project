Rails.application.routes.draw do
  devise_for :users

  resources :game_projects, only: [:index, :show, :new, :create]
  resources :rulebook_versions, only: [] do
    resources :playtest_sessions, only: [:create]
  end
  resources :playtest_sessions, only: [:update] do
    resources :feedbacks, only: [:create]
  end
  root "game_projects#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers or uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end