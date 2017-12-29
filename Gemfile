source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.8'

# Use sqlite3 or mysql2 as the databases for Active Record
gem 'sqlite3'
gem 'mysql2', '0.3.18'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'mini_racer',  platforms: :ruby
gem 'libv8'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Hydra stack
gem 'nokogiri', '~> 1.8.1'
gem 'blacklight', '~> 5.19'
gem 'hydra-head', '~>7'

# Columbia Hydra models
gem 'cul_hydra', '~> 1.4.8'
#gem 'cul_hydra', :path => '../cul_hydra'
gem 'active_fedora_relsint', :git => 'https://github.com/cul/active_fedora_relsint.git', :branch => 'master'

# Use imogen for generating images
gem 'imogen', '0.1.7'
#gem 'imogen', :path => '../imogen'

# Use rmagick for pdf image derivatives
gem 'rmagick'

# Use streamio-ffmpeg for audio/video
gem 'streamio-ffmpeg', '~> 3.0'

# For http requests
gem 'rest-client'

# Use free-image gem fork
gem 'free-image', :git => 'https://github.com/barmintor/free-image-ruby.git', :branch => 'master'

# For retrying code blocks that may return an error
gem 'retriable', '~> 2.1'

# Use resque for background jobs
# We're pinning resque to 1.26.x because 1.27 does an eager load operation
# that doesn't work properly with the Blacklight gem dependency and raises:
# ActiveSupport::Concern::MultipleIncludedBlocks: Cannot define multiple 'included' blocks for a Concern
gem 'resque', '~> 1.26.0'
gem 'redis', '< 4' # Need to lock to earlier version of redis gem because resque is calling Redis.connect, and this method no longer exists in redis gem >= 4.0

# Use redis-rails for redis-backed rails cache
gem 'redis-rails'
gem 'redis-store', '>= 1.4.0'

# OpenSeadragon js viewer. Helpers + assets
gem 'openseadragon'

# URI Escaping
gem 'addressable', '~> 2.5'

# Ensure min version of rubyzip because of security vulnerability in earlier version
gem 'rubyzip', '>= 1.2.1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  
  gem 'rspec-rails', '~> 3.5'
  gem 'jettywrapper', '>= 1.5.1'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.5.0', require: false
  # Rails and Bundler integrations were moved out from Capistrano 3
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-bundler', '~> 1.1', require: false
  # "idiomatic support for your preferred ruby version manager"
  gem 'capistrano-rvm', '~> 0.1', require: false
  # The `deploy:restart` hook for passenger applications is now in a separate gem
  # Just add it to your Gemfile and require it in your Capfile.
  gem 'capistrano-passenger', '~> 0.1', require: false
end

