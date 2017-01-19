# For EXTREME debugging with full stack traces.  Woo!
Rails.backtrace_cleaner.remove_silencers! if Rails.env.development?

DERIVATIVO = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file("#{Rails.root}/config/derivativo.yml")[Rails.env])