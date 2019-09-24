# Derivativo 2

Derivativo is derivative generation app that converts images, audio, video, office documents, and PDFs.

## Requirements

- Ruby 2.6
- Redis 3
- More to come (for audio, video, image conversion, etc.)

## First-Time Setup (for developers)

```
git clone git@github.com:cul/ren-derivativo.git # Clone the repo
cd ren-derivativo # Switch to the application directory
# Note: Make sure rvm has selected the correct ruby version. You may need to move out of the directory and back into it force rvm to use the ruby version specified in .ruby_version.
bundle install # Install gem dependencies
yarn install # this assumes you have node and yarn installed (tested with Node 8 and Node 10)
bundle exec rake derivativo:setup:config_files # Set up config files like redis.yml and resque.yml
bundle exec rake db:migrate # Run database migrations
bundle exec rake derivativo:setup:default_users # Set up default Derivativo users
rails s -p 3000 # Start the application using rails server
```
And for faster React app recompiling during development, run this in a separate terminal window:

```
./bin/webpack-dev-server
```

## Testing
Our testing suite runs Rubocop and then runs all of our ruby tests. Travis CI will automatically run the test suite for every commit and pull request.

To run the continuous integration test suite locally on your machine run:
```
bundle exec rake derivativo:ci
```
