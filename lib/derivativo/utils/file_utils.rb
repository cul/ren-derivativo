module Derivativo::Utils::FileUtils
  
  # Blocks until a file is found at the given path, or until timeout passes
  def self.block_until_file_exists(path_to_file, retry_interval=0.25, number_of_retries=3)
    number_of_retries.times do
        return true if File.exists?(path_to_file)
        sleep retry_interval
    end
    false
  end
  
end