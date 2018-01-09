rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env = ENV['RAILS_ENV'] || 'development'
IIIF_TEMPLATES = YAML.load_file(rails_root + '/config/iiif_templates.yml').freeze
