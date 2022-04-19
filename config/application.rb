require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Derivativo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Custom directories with classes and modules you want to be eager loaded.
    config.eager_load_paths += %W[#{config.root}/lib]

    config.after_initialize do
      # Ensure that cache path exists
      raise 'Please specifiy a cache_base_directory in derivativo.yml' if DERIVATIVO[:cache_base_directory].blank?
      raise 'Please specifiy a cache_iiif_directory in derivativo.yml' if DERIVATIVO[:cache_iiif_directory].blank?
      FileUtils.mkdir_p(DERIVATIVO[:cache_base_directory])
      FileUtils.mkdir_p(DERIVATIVO[:cache_iiif_directory])
    end
  end
end
