# frozen_string_literal: true

namespace :derivativo do
  namespace :setup do
    desc 'Set up application config files'
    task :config_files do
      config_template_dir = Rails.root.join('config/templates')
      config_dir = Rails.root.join('config')
      Dir.foreach(config_template_dir) do |entry|
        next unless entry.end_with?('.yml')

        src_path = File.join(config_template_dir, entry)
        dst_path = File.join(config_dir, entry.gsub('.template', ''))
        if File.exist?(dst_path)
          puts "#{Rainbow("File already exists (skipping): #{dst_path}").blue.bright}\n"
        else
          FileUtils.cp(src_path, dst_path)
          puts Rainbow("Created file at: #{dst_path}").green
        end
      end

      # Optional params that are mostly just used by the CI environment
      if ENV['TIKA_JAR_PATH']
        derivativo_config_file_path = File.join(config_dir, 'derivativo.yml')
        derivativo_config = YAML.load(File.read(derivativo_config_file_path))
        derivativo_config[Rails.env]['tika_jar_path'] = ENV['TIKA_JAR_PATH']
        File.write(derivativo_config_file_path, YAML.dump(derivativo_config))
      end
    end
  end
end
