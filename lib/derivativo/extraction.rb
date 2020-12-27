# frozen_string_literal: true

require 'benchmark'

module Derivativo
  module Extraction
    def self.extract_fulltext(src_file_path:, dst_file_path:)
      Rails.logger.info "Extracting fulltext for #{src_file_path} ..."
      time = Benchmark.measure do
        tika_extract_text(src_file_path: src_file_path, dst_file_path: dst_file_path, tika_jar_path: DERIVATIVO['tika_jar_path'])
      end
      Rails.logger.info("Finished extracting fulltext for file #{src_file_path} at #{dst_file_path} in #{time.real} seconds.")
    end

    def self.tika_extract_text(src_file_path:, dst_file_path:, tika_jar_path:)
      conversion_command = [
        'java',
        '-jar',
        tika_jar_path,
        '--text',
        Shellwords.escape(src_file_path),
        '>',
        Shellwords.escape(dst_file_path)
      ].join(' ')

      _stdout_str, stderr_str, _status = Open3.capture3(conversion_command)

      # Tika puts informational messages in stderr that we generally don't care about, so we'll
      # redirect that text to debug level output in case it's ever useful while debugging.
      Rails.logger.debug(stderr_str)

      Derivativo::FileHelper.block_until_file_exists(dst_file_path)
    end
  end
end
