require 'addressable/uri'

class Derivativo::TikaTextExtractor

  def self.extract_text_from_file(path_to_file)

    filename = File.basename(path_to_file)

    # Read entire file into memory (since the whole thing needs to get sent tika over http anyway)
    file_content = IO.binread(path_to_file)

    tika_extract_text(src_file_path: path_to_file, tika_jar_path: DERIVATIVO['tika_jar_path'])
  end

  def self.tika_extract_text(src_file_path:, tika_jar_path:)
    conversion_command = [
      'java',
      '-jar',
      tika_jar_path,
      '--text',
      Shellwords.escape(src_file_path)
    ].join(' ')

    stdout_str, stderr_str, _status = Open3.capture3(conversion_command)

    # Tika puts informational messages in stderr that we generally don't care about, so we'll
    # redirect that text to debug level output in case it's ever useful while debugging.
    Rails.logger.debug(stderr_str)

    stdout_str
  end
end
