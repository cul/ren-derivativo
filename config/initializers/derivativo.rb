# For EXTREME debugging with full stack traces.  Woo!
Rails.backtrace_cleaner.remove_silencers! if Rails.env.development?

DERIVATIVO = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file("#{Rails.root}/config/derivativo.yml")[Rails.env])

# Override default FFMPEG path from DERIVATIVO config if present
FFMPEG.ffmpeg_binary = DERIVATIVO['ffmpeg_binary_path'] if File.exist?(DERIVATIVO['ffmpeg_binary_path'].to_s)
FFMPEG.ffprobe_binary = DERIVATIVO['ffprobe_binary_path'] if File.exist?(DERIVATIVO['ffprobe_binary_path'].to_s)
