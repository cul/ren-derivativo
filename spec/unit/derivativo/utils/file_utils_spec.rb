require 'rails_helper'

describe Derivativo::Utils::FileUtils do
  
  context ".block_until_file_exists" do
    let(:retry_interval) { 1.0 }
    let(:num_retries) { 3 }
    
    it "will not sleep for :check_interval and will return immediately if file is found" do
      file = Tempfile.new('foo')
      begin
        start_time = Time.now
        result = Derivativo::Utils::FileUtils.block_until_file_exists(file.path, retry_interval, num_retries)
        expect(Time.now-start_time).to be < retry_interval
        expect(result).to be true
      ensure
         file.close
         file.unlink
      end
    end
    
    it "will check max number of times for a file that doesn't exist and will return false" do
      non_existent_file_path = '/definitely/does/not/exist/25379/25370/file'
      start_time = Time.now
      result = Derivativo::Utils::FileUtils.block_until_file_exists(non_existent_file_path, retry_interval, num_retries)
      timing_margin_of_error = retry_interval * 0.1 # add a margin of error to our time comparison to account for minor timing differences in test
      expect(Time.now-start_time).to be >= ((num_retries * retry_interval) - timing_margin_of_error)
      expect(result).to be false
    end
  end
  
end