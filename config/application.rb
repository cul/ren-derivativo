# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Derivativo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Rails app will use the Eastern time zone
    config.time_zone = 'Eastern Time (US & Canada)'

    # Database will store dates in UTC
    # (This is the rails default behavior, but we're being explicit.)
    config.active_record.default_timezone = :utc

    # Auto-load lib files
    config.eager_load_paths << Rails.root.join('lib')
  end
end
