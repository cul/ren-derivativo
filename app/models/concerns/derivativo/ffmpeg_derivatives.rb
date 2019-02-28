module Derivativo::FfmpegDerivatives
	extend ActiveSupport::Concern

	def derivative_proc_for_output_path(out_path)
		Proc.new do |in_path|
			movie = FFMPEG::Movie.new(in_path)
			movie.transcode(out_path, ffmpeg_output_args, {input_options: ffmpeg_input_args})
		end
	end

	def ffmpeg_output_args
		DERIVATIVO[media_type + '_access_copy_settings']['ffmpeg_output_args'].split(' ')
	end

	def ffmpeg_input_args
		# streamio ffmpeg library expects ffmpeg input args to be a hash. an array is not currently accepted.
		args_as_hash = {}
		args = DERIVATIVO[media_type + '_access_copy_settings']['ffmpeg_input_args'].split(' ')
		args.each_with_index do |arg, i|
			if arg.start_with?('-')
				arg_without_hyphen = arg[1...arg.length]
				if args.length == i + 1 || args[i+1].start_with?('-')
					args_as_hash[arg_without_hyphen] = nil # final arg in list OR hyphen arg followed by another hyphen arg
				else
					args_as_hash[arg_without_hyphen] = args[i+1]
				end
			end
		end
		args_as_hash
	end
end