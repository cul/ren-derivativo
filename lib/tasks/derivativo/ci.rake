# frozen_string_literal: true

# Only include this task in development and test environments (because rspec is only available
# in those environments and we don't ever want to run CI tasks in other environments).
if ['development', 'test'].include?(Rails.env)
  namespace :derivativo do
    require 'rspec/core/rake_task'
    RSpec::Core::RakeTask.new(:rspec) do |spec|
      spec.rspec_opts ||= []
      spec.rspec_opts << '--backtrace' if ENV['CI']
    end

    require 'rubocop/rake_task'
    desc 'Run style checker'
    RuboCop::RakeTask.new(:rubocop) do |task|
      task.requires << 'rubocop-rspec'
      task.fail_on_error = true
    end

    desc 'CI build without rubocop'
    task ci_nocop: ['derivativo:setup:config_files', :environment, 'derivativo:ci_specs']

    desc 'CI build with Rubocop validation'
    task ci: ['derivativo:setup:config_files', :environment, 'derivativo:rubocop', 'derivativo:ci_specs']

    desc 'CI build just running specs'
    task ci_specs: :environment do
      rspec_system_exit_failure_exception = nil

      duration = Benchmark.realtime do
        ENV['RAILS_ENV'] = 'test'
        Rails.env = ENV['RAILS_ENV']

        Rake::Task['db:environment:set'].invoke
        Rake::Task['db:drop'].invoke
        Rake::Task['db:create'].invoke
        Rake::Task['db:migrate'].invoke
        begin
          Rake::Task['derivativo:rspec'].invoke
        rescue SystemExit => e
          rspec_system_exit_failure_exception = e
        end
      end
      puts "CI run finished in #{duration} seconds."
      # If present, re-raise any caught exit exception after CI duration display,
      # so we can still display the run time even when a system exception comes up.
      # This exception triggers an exit call with the original error code sent out by rspec failure.
      raise rspec_system_exit_failure_exception unless rspec_system_exit_failure_exception.nil?
    end
  end
end
