require 'resque/server'

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: redirect('ui/v1')
  get 'ui', to: redirect('ui/v1')
  get 'ui/v1', to: 'ui#v1'
  # wildcard *path route so that everything under ui/v1 gets routed to the single-page app
  get 'ui/v1/*path', to: 'ui#v1'

  # Resque setup
  resque_web_constraint = lambda do |_request|
    # TODO: Setup devise so resque-web is behind authentication

    # current_user = request.env['warden'].user
    # current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
    true
  end
  constraints resque_web_constraint do
    mount Resque::Server.new, at: "/resque"
  end
end
