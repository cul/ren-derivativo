# frozen_string_literal: true

module Derivativo
  module Conversion
    module FfmpegHelpers
      # Converts an input audiovisual file to an output audiovisual file
      def self.ffmpeg_convert(src_file_path:, dst_file_path:, ffmpeg_output_args:, ffmpeg_input_args: nil)
        movie = FFMPEG::Movie.new(src_file_path)
        movie.transcode(
          dst_file_path, ffmpeg_output_args.split(' '),
          input_options: ffmppeg_input_args_string_as_hash(ffmpeg_input_args)
        )
        Derivativo::FileHelper.block_until_file_exists(dst_file_path)
      end

      def self.ffmpeg_video_screenshot(src_file_path:, dst_file_path:, size: nil)
        movie = FFMPEG::Movie.new(src_file_path)
        halfway_point = (movie.duration / 2).floor
        screenshot_args = {
          vframes: 1,
          quality: 4,
          seek_time: halfway_point
        }
        screenshot_args['resolution'] = scaled_resolution_for_movie(size).join('x') if size.present?
        movie.screenshot(dst_file_path, screenshot_args)
      end

      # For the given FFMPEG::Movie object, calculates and returns a scaled resolution that retains
      # the movie's aspect ratio but scales the longer dimension (width or height) to the specified
      # size.
      # @return [Array] The scaled width and height, with width at index 0 and height at index 1
      #                 (example: [960, 540]).
      def self.scaled_resolution_for_movie(movie, size)
        width, height = nil
        if movie.width >= movie.height
          width = size
          height = movie.height * (size / movie.width)
        else
          height = size
          width = movie.width * (size / movie.height)
        end
        [width, height]
      end

      # For the ffmpeg library that we're using, input args must be a hash.  Input arg keys are
      # never repatable, so this is fine. Note that by contrast, output args CAN have repeatable
      # keys (like "-map"), so this method should never be used for output args.
      def self.ffmppeg_input_args_string_as_hash(spaced_args)
        return {} if spaced_args.nil?

        args_as_arr = spaced_args.split(' ')
        args_as_hash = {}

        args_as_arr.each_with_index do |arg, i|
          # Arguments can either be standalone dash-prefixed keys OR dash-prefixed keys followed by a non-dash-prefixed value.
          next unless arg.start_with?('-')

          key = arg.delete_prefix('-')
          is_final_argument = args_as_arr.length == i + 1
          # If this argument is the final argument OR if it is followed by another argument that
          # starts with a dash, this is a single, standalone argument and we should assign a value
          # of nil to the key.  Otherwise we'll assign the i+1 argument as the value associated
          # with this key.
          args_as_hash[key] = is_final_argument || args_as_arr[i + 1].start_with?('-') ? nil : args_as_arr[i + 1]
        end

        args_as_hash
      end
    end
  end
end
