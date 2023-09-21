# frozen_string_literal: true

module Derivativo
  class UserPathHelper
    # Checks the user's $PATH for the given program
    def self.which(program)
      exts = pathext_values
      path_values.each do |path|
        exts.each do |ext|
          # Do a case-insensitive search (e.g. because windows stores PATHEXT extensions as
          # capitalized strings and these won't match the on-disk versions of executables).
          # Note that it's possible to have case-sensitive volumes (or directories) on both
          # windows and unix-like systems (though extension matching is less likely to be a
          # problem on unix-like systems.
          possible_executable_file = case_sensitive_file_path(path, "#{program}#{ext}")
          return possible_executable_file if possible_executable_file.present? && File.executable?(possible_executable_file)
        end
      end

      nil
    end

    # Given a directory and filename, does a case insensitive search for the filename within the
    # directory and returns the full, case-sensitive path to the first matching file.
    def self.case_sensitive_file_path(dir_path, case_insensitve_filename_to_search_for)
      return nil unless Dir.exist?(dir_path)

      Dir.each_child(dir_path) do |filename|
        return File.join(dir_path, filename) if filename.casecmp(case_insensitve_filename_to_search_for).zero?
      end
      nil
    end

    def self.pathext_values
      ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    end

    def self.path_values
      ENV['PATH'] ? ENV['PATH'].split(File::PATH_SEPARATOR) : ['']
    end
  end
end
