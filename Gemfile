source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.7.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', '>= 0.12.2',  platforms: :ruby
gem 'libv8', '>= 3.16.14.15' # Min version for Mac OS 10.11, XCode 8.0

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

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Hydra stack
gem 'nokogiri', '~> 1.7.0'
gem 'blacklight', '>= 5.4.0'
gem 'hydra-head', '~>7'

# Columbia Hydra models
gem 'cul_hydra', '~> 1.4.5'
#gem 'cul_hydra', :path => '../cul_hydra'
gem 'active_fedora_relsint', :git => 'https://github.com/cul/active_fedora_relsint.git', :branch => 'master'

# Use imogen for generating images
gem 'imogen', '0.1.7'

# Use rmagick for pdf image derivatives
gem 'rmagick'

# For http requests
gem 'rest-client'

# Use free-image gem fork
gem 'free-image', :git => 'https://github.com/barmintor/free-image-ruby.git', :branch => 'master'

# For retrying code blocks that may return an error
gem 'retriable', '~> 2.1'

# Use resque for background jobs
gem 'resque', '~> 1.0'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  
  gem 'rspec-rails', '~> 3.5'
  gem 'jettywrapper', '>= 1.5.1'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
end

