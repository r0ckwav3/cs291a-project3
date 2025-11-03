Rails.application.routes.draw do
  get "health", to: "health#show"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "conversations/", to: "conversations#index"
  get "conversations/:id", to: "conversations#show"
  post "conversations/", to: "conversations#create"
  get "conversations/:id/messages", to: "conversations#messages"
  post "messages/", to:"conversations#post_message"
  put "messages/:id/read", to:"conversations#mark_message_read"

  post "auth/register"
  post "auth/login"
  post "auth/logout"
  post "auth/refresh"
  get "auth/me"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # get "health" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
