# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# Enable resque tasks and ensure that setup and work tasks have access to the environment
require 'resque/tasks'
task "resque:setup" => :environment
task "resque:work" => :environment

require_relative 'config/application'
Rails.application.load_tasks
