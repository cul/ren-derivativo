#server "#{fetch(:instance)}-nginx-#{fetch(:stage)}1.cul.columbia.edu", user: fetch(:remote_user), roles: %w(app db web)

# Manual override to ren-nginx-prod2
server "ren-nginx-prod2.cul.columbia.edu", user: fetch(:remote_user), roles: %w(app db web)

# Override all variables related to deploy_name
# (This is temporary, just while we test the processing_new deploy environment.)
set :deploy_name, "#{fetch(:application)}_processing"
set :rails_env, fetch(:deploy_name)
set :rvm_ruby_version, fetch(:deploy_name)
set :deploy_to,   "/opt/passenger/#{fetch(:instance)}/#{fetch(:deploy_name)}"

# In test/prod, deploy from release tags; most recent version is default
ask :branch, proc { `git tag --sort=version:refname`.split("\n").last }
