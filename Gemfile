# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Amazon S3 SDK
gem 'aws-sdk-s3', '~> 1'
# Additional gem enabling the AWS SDK to calculate CRC32C checksums
gem 'aws-crt', '~> 0.2.0'
# Use best_type for media type detection
gem 'best_type', '~> 0.0.10'
# For schema validation
gem 'dry-validation', '~> 1.9'
# Factory bot for model fixtures
gem 'factory_bot_rails', '~> 6.2'
# Faraday for http requests
gem 'faraday', '~> 2.7' # core faraday library
gem 'faraday-multipart', '~> 1.0' # for added file upload functionality
# Use imogen for generating images
# gem 'imogen', '~> 0.4.0'
# gem 'imogen', path: '../imogen'
gem 'imogen', git: 'https://github.com/cul/imogen.git', branch: 'iiif_tile_generation_fixes'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use mysql as a database option for Active Record
gem 'mysql2', '~> 0.5.5'
# Use Puma as the app server
gem 'puma', '~> 5.2'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.8'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.8' # NOTE: Updating the redis gem to v5 breaks the current redis namespace setup
gem 'redis-namespace', '~> 1.11'
# Resque for queued jobs
gem 'resque', '~> 2.6'
# Rainbow for text coloring
gem 'rainbow', '~> 3.0'
# Use sqlite3 as a database option for Active Record
gem 'sqlite3', '~> 1.4'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5'
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'
# For ffmpeg video conversion
gem 'streamio-ffmpeg', '~> 3.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

gem 'addressable', '~> 2.7.0'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

# Vite for frontend UI
gem 'vite_rails', '~> 3.0'

group :development, :test do
  # rubocop + CUL presets
  gem 'rubocul', '~> 4.0.6'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # rspec for testing
  gem 'rspec', '>= 3.11'
  gem 'rspec-rails', '~> 6.0'
  # json_spec for easier json comparison in tests
  gem 'json_spec'
  # simplecov for test coverage reports
  gem 'simplecov', '~> 0.22', require: false
  # for mocking http requests in tests
  gem 'webmock'
end

group :development do
  # Capistrano gems for deployment
  gem 'capistrano', '~> 3.18.0', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false
  gem 'capistrano-rails', '~> 1.4', require: false

  gem 'listen', '~> 3.3'
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
