# frozen_string_literal: true

module Derivativo
  module FileHelper
    def self.file_location_to_file_path(file_location)
      # Note 1: Right now we're only expecting 'file://'-prefixed locations (as opposed to 'https://' or others),
      # but one day we might download the file from a URL if we're storing files on AWS, or if we run into
      # file-reading permission issues on a regular basis.
      # Note 2: We match against three slashes because we're expecting the 'file://' protocol
      # followed by a slash-prefixed full file path.
      unless file_location.start_with?('file:///')
        raise Derivativo::Exceptions::UnhandledLocationFormat,
              "Unhandled location format: #{file_location}"
      end

      file_path = file_location.gsub(/^file:\/\//, '')
      raise Derivativo::Exceptions::UnreadableFilePath, 'Unable to read file at: ' unless File.readable?(file_path)

      file_path
    end

    # Creates a Tempfile in the application's "working directory" with a random name and optional
    # prefix and suffix.  If a block is given, this method yields the Tempfile object and
    # immediately deletes the file after the block completes.  If no block is given, the tempfile
    # is returned and not immediately deleted, but remember that this is an actual Ruby Tempfile
    # and the Tempfile might be deleted as soon as Ruby garbage collection runs if there are no
    # longer any references to its variable.  Tempfile deletion timing can be unpredictable, so
    # it's always best to explicitly delete a tempfile as soon as you're done with it.
    def self.working_directory_temp_file(prefix = '', suffix = '', binmode = true)
      file = Tempfile.new([prefix, suffix], DERIVATIVO['working_directory'], binmode: binmode)
      yield file if block_given?
      file
    ensure
      # Close and unlink the tempfile
      file&.close! if block_given?
    end

    # Creates a temporary directory in the working directory with a random name and optional suffix,
    # yields the Dir object and automatically deletes the directory after the passed-in block
    # completes.
    def self.working_directory_temp_dir(suffix)
      # This method leverages existing temp file functionality to avoid name collisions.
      working_directory_temp_file('', '') do |temp_file|
        dir_path = "#{temp_file.path}-dir-#{suffix}"
        FileUtils.mkdir(dir_path)
        dir = Dir.new(dir_path)
        yield dir if block_given?
      ensure
        # Delete the temp directory
        FileUtils.rm_rf(dir_path) if block_given?
      end
    end

    # Waits for a while until a file is found at the given path, periodically checking along a
    # given retry_interval.  One the number_of_retries has been exceeded, raises an exception
    # if the file is still not found.
    def self.block_until_file_exists(path_to_file, retry_interval = 0.25, number_of_retries = 3)
      return true if File.exist?(path_to_file)

      number_of_retries.times do
        sleep retry_interval
        return if File.exist?(path_to_file)
      end
      raise Derivativo::Exceptions::TimeoutException, "Waited for a while, but did not find file at: #{path_to_file}"
    end
  end
end
