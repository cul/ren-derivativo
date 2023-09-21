# frozen_string_literal: true

require Rails.root.join('config/environments/deployed.rb')

Rails.application.configure do
  # Setting host so that url helpers can be used in mailer views.
  config.action_mailer.default_url_options = { host: 'https://derivativo-new.library.columbia.edu' }
end
