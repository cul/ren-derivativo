source 'https://rubygems.org'

gem 'bootsnap', require: false
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.4'

# Use sqlite3 or mysql2 as the databases for Active Record
gem 'mysql2', '~> 0.5'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
#gem 'libv8', '>= 3.16.14.19' # Min version for Mac OS 10.11, XCode 9.0, Ruby 2.4

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

gem 'nokogiri', '~> 1.10.10' # can't update to 1.11 because our server version of GLIBC is too old

# Columbia Hydra models
gem 'cul_hydra', :git => 'https://github.com/cul/cul_hydra.git', :branch => 'master'
#gem 'cul_hydra', :path => '../cul_hydra'
gem 'active_fedora_relsint', :git => 'https://github.com/cul/active_fedora_relsint.git', :branch => 'master'
gem 'blacklight', '~> 7.22'
gem 'view_component', '~> 2.51.0'
# Use imogen for generating images
gem 'imogen', '0.2.1'
gem 'ruby-vips', '~> 2.0.16'
#gem 'imogen', :path => '../imogen'

# Use best type for mime/dc lookups
gem 'best_type', '0.0.9'

# Use streamio-ffmpeg for audio/video
# https://github.com/streamio/streamio-ffmpeg
gem 'streamio-ffmpeg', '~> 3.0'

# For http requests
gem 'rest-client'

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

# Lock on logger ~> 1.2.8.1 until we upgrade app past ruby 2.2
gem 'logger', '~> 1.2.8.1'

# Gem min versions that are only specified here because of vulnerabilities in earlier versions:
gem 'rubyzip', '>= 1.2.1'
gem 'rack-protection', '>= 1.5.5'
gem 'loofah', '>= 2.3.1'

group :development, :test do
  gem 'sqlite3'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'rspec-rails', '~> 5.0.2'
  gem 'jettywrapper', '>=2.0.5', git: 'https://github.com/samvera-deprecated/jettywrapper.git', branch: 'master'
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
  gem 'listen'
end
