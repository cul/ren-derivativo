require 'resque/server'

Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  mount Resque::Server.new, at: "/resque"

  # You can have the root of your site routed with "root"
  root 'pages#home'

  namespace :iiif do
    scope ':version', version: /2/, defaults: { version: 2 } do
      defaults format: :json do
        get '/presentation/:id', to: 'presentations#show', as: :presentation
        delete '/presentation/:id', to: 'presentations#destroy'
        get '/presentation/:id/manifest', to: 'presentations#manifest', as: :manifest
        get '/presentation/:presentation_id/range/:id', to: 'presentations#range', as: :range
        get '/presentation/:presentation_id/canvas/:id', to: 'presentations#canvas', as: :canvas
        get '/presentation/:presentation_id/annotation/:id', to: 'presentations#annotation', as: :annotation
        get '/:id', to: 'images#iiif_id', as: 'id'
        get '/:id/info.:format', to: 'images#info', as: 'info'
      end
      get '/:id/:region/:size/:rotation/:quality', to: 'images#raster', as: 'raster'
    end
  end

  resources :resources, only: [:index, :update, :destroy] do
    member do
      delete 'destroy_cachable_properties'
    end
  end

  get '/examples/zooming_viewer', to: 'examples#zooming_viewer', as: 'zooming_viewer_example'

  namespace :v0 do
    post 'thumbnails', to: 'thumbnails#create'
    post 'thumbnails2', to: 'thumbnails#create2'
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
