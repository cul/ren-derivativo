# frozen_string_literal: true

require 'resque/server'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root 'pages#home'

  # Constraint for restricting certain routes to only admins, or to the development environment
  dev_or_admin_constraints = lambda do |_request|
    # TODO: Setup devise so resque-web is behind authentication

    # return true if Rails.env.development?
    # current_user = request.env['warden'].user
    # current_user&.is_admin?
    true
  end

  constraints dev_or_admin_constraints do
    mount Resque::Server.new, at: '/resque'
  end

  namespace :api do
    namespace :v1, defaults: { format: :json } do
      resources :resource_request_jobs
      resources :derivative_requests, only: [:create]
    end
  end
end
