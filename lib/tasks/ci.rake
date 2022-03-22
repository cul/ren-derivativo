namespace :derivativo do
  # Note: Don't include Rails environment for this task, since enviroment includes a check for the presence of database.yml
  task :config_files do
    # yml templates
    Dir.glob(File.join(Rails.root, "config/templates/*.template.yml")).each do |template_yml_path|
      target_yml_path = File.join(Rails.root, 'config', File.basename(template_yml_path).sub(".template.yml", ".yml"))
      next if File.exist?(target_yml_path)
      FileUtils.touch(target_yml_path) # Create if it doesn't exist
      target_yml = YAML.load_file(target_yml_path) || YAML.load_file(template_yml_path)
      File.open(target_yml_path, 'w') {|f| f.write target_yml.to_yaml }
    end
    Dir.glob(File.join(Rails.root, "config/templates/*.template.yml.erb")).each do |template_yml_path|
      target_yml_path = File.join(Rails.root, 'config', File.basename(template_yml_path).sub(".template.yml.erb", ".yml"))
      next if File.exist?(target_yml_path)
      FileUtils.touch(target_yml_path) # Create if it doesn't exist
      target_yml = YAML.load_file(target_yml_path) || YAML.load(ERB.new(File.read(template_yml_path)).result(binding))
      File.open(target_yml_path, 'w') {|f| f.write target_yml.to_yaml }
    end
  end
end
