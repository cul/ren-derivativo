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

    # Active Job
    config.active_job.queue_name_prefix = "#{Rails.application.class.module_parent_name}.#{Rails.env}"
    config.active_job.queue_name_delimiter = '.'
    config.after_initialize do
      config.active_job.queue_adapter = DERIVATIVO[:run_background_jobs_inline] ? :inline : :resque
    end
  end
end
