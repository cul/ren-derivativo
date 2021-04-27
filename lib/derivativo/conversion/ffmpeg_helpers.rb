# frozen_string_literal: true

module Derivativo
  module Conversion
    module FfmpegHelpers
      # Converts an input audiovisual file to an output audiovisual file
      def self.ffmpeg_convert(src_file_path:, dst_file_path:, ffmpeg_output_args:, ffmpeg_input_args: nil)
        movie = FFMPEG::Movie.new(src_file_path)
        movie.transcode(dst_file_path, ffmpeg_output_args.split(' '), input_options: ffmppeg_input_args_string_as_hash(ffmpeg_input_args))
        Derivativo::FileHelper.block_until_file_exists(dst_file_path)
      end

      def self.ffmpeg_video_screenshot(src_file_path:, dst_file_path:)
        movie = FFMPEG::Movie.new(src_file_path)
        halfway_point = (movie.duration / 2).floor
        screenshot_args = {
          vframes: 1,
          quality: 4,
          seek_time: halfway_point
        }
        movie.screenshot(dst_file_path, screenshot_args)
      end

      # For the ffmpeg library that we're using, input args must be a hash.  Input arg keys are never repatable, so this is fine.
      # Note that by contrast, output args CAN have repeatable keys (like "-map"), so this method should never be used for output args.
      def self.ffmppeg_input_args_string_as_hash(spaced_args)
        return {} if spaced_args.nil?
        args_as_arr = spaced_args.split(' ')
        args_as_hash = {}

        args_as_arr.each_with_index do |arg, i|
          # Arguments can either be standalone dash-prefixed keys OR dash-prefixed keys followed by a non-dash-prefixed value.
          next unless arg.start_with?('-')

          key = arg.delete_prefix('-')
          if args_as_arr.length == i + 1 || args_as_arr[i + 1].start_with?('-')
            # This is either the final argument in the list OR a dash-prefixed argument that's followed by a different dash-prefixed argument.
            # Either way, assign associated value to nil.
            args_as_hash[key] = nil
          else
            # Assign the next argument as the value associated with the current argument key.
            args_as_hash[key] = args_as_arr[i + 1]
          end
        end

        args_as_hash
      end
    end
  end
end
