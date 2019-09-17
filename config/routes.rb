Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: redirect('ui/v1')
  get 'ui', to: redirect('ui/v1')
  get 'ui/v1', to: 'ui#v1'
  # wildcard *path route so that everything under ui/v1 gets routed to the single-page app
  get 'ui/v1/*path', to: 'ui#v1'
end
