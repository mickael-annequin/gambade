Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  resource :dog, only: %i[show new create edit update]
  resources :walks do
    get :map, on: :collection # /walks/map: all the tracks on one map
    resource :trim, only: %i[edit update], controller: "walk_trims"
    resource :notes, only: %i[edit update], controller: "walk_notes"
    resources :encounters, only: %i[edit update destroy]
    resources :activities, only: :destroy
    resources :photos, only: %i[create destroy], controller: "walk_photos"
  end
  resources :tracked_walks, only: %i[new create]
  resources :friends
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA: lets Android install Gambade on the home screen (app/views/pwa/manifest.json.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
