# frozen_string_literal: true

# For EXTREME debugging with full stack traces.  Woo!
# Rails.backtrace_cleaner.remove_silencers! if Rails.env.development?

# Tell vips NOT to cache image conversion operations
#Vips.cache_set_max(0) # this solves the problem
#Vips.cache_set_max_files(0) # this solves the problem

# Cache the app version
APP_VERSION = File.read(Rails.root.join('VERSION'))

# Set the placeholder directory path
PLACEHOLDER_DIRECTORY_PATH = Rails.root.join('public/placeholders/dark')

# Load the derivativo config
DERIVATIVO = ActiveSupport::HashWithIndifferentAccess.new(
  YAML.unsafe_load_file(Rails.root.join('config/derivativo.yml'))[Rails.env]
)

# Load the fedora config
FEDORA_CONFIG = ActiveSupport::HashWithIndifferentAccess.new(
  YAML.unsafe_load_file(Rails.root.join('config/fedora.yml'))[Rails.env]
)

# Load the Hyacinth config
HYACINTH_CONFIG = ActiveSupport::HashWithIndifferentAccess.new(
  YAML.unsafe_load_file(Rails.root.join('config/hyacinth.yml'))[Rails.env]
)

# Create the specified tmpdir, if it was provided and if it doesn't already exist
FileUtils.mkdir_p(DERIVATIVO['tmpdir']) if DERIVATIVO['tmpdir'].present?

IIIF_TILE_SIZE = 512

# Override default FFMPEG path from DERIVATIVO config if present
# FFMPEG.ffmpeg_binary = DERIVATIVO['ffmpeg_binary_path'] if File.exist?(DERIVATIVO['ffmpeg_binary_path'].to_s)
# FFMPEG.ffprobe_binary = DERIVATIVO['ffprobe_binary_path'] if File.exist?(DERIVATIVO['ffprobe_binary_path'].to_s)

Rails.configuration.after_initialize do
  # On application startup, copy all placeholders to the base directory if they do not already exist
  Dir[File.join(PLACEHOLDER_DIRECTORY_PATH, '*.png')].each do |path_to_placeholder_file|
    file_extension = File.extname(path_to_placeholder_file)
    filename_without_extension = File.basename(path_to_placeholder_file, file_extension)
    resource = ::Resource.new("placeholder:#{filename_without_extension}")
    base_cache_path = resource.base_cache_path(true)
    if !File.exist?(base_cache_path)
      FileUtils.cp(path_to_placeholder_file, resource.base_cache_path(true))
    end
  end
end
