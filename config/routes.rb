# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'pages#home'

  resources :resources, only: [:update, :destroy] do
    member do
      delete 'destroy_cachable_properties'
    end
  end

  namespace :iiif do
    scope ':version', version: /2/, registrant: /10\.[^\/]+/, doi: /[^\/]+/,
                      manifest_registrant: /10\.[^\/]+/, manifest_doi: /[^\/]+/,
                      defaults: { version: 2 } do
      defaults format: 'json' do
        get '/:id', to: 'images#iiif_id', as: 'id'
        get '/:id/info.:format', to: 'images#info', as: 'info'
      end
      get '/:id/:region/:size/:rotation/:quality', to: 'images#raster', as: 'raster'
    end
  end
end
