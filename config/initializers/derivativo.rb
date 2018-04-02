# For EXTREME debugging with full stack traces.  Woo!
Rails.backtrace_cleaner.remove_silencers! if Rails.env.development?

DERIVATIVO = ActiveSupport::HashWithIndifferentAccess.new(YAML.load_file("#{Rails.root}/config/derivativo.yml")[Rails.env])

# Override default FFMPEG path from DERIVATIVO config if present
FFMPEG.ffmpeg_binary = DERIVATIVO['ffmpeg_binary_path'] if DERIVATIVO['ffmpeg_binary_path'].present?
FFMPEG.ffprobe_binary = DERIVATIVO['ffprobe_binary_path'] if DERIVATIVO['ffprobe_binary_path'].present?
