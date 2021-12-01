# frozen_string_literal: true

DERIVATIVO = Rails.application.config_for(:derivativo)

FFMPEG.ffmpeg_binary = DERIVATIVO['ffmpeg_binary_path'] if DERIVATIVO['ffmpeg_binary_path'].present?
FFMPEG.ffprobe_binary = DERIVATIVO['ffprobe_binary_path'] if DERIVATIVO['ffprobe_binary_path'].present?

# If no working_directory is set, use default tmpdir.
if DERIVATIVO['working_directory'].blank?
  DERIVATIVO['working_directory'] = Dir.tmpdir
else
  # Create user-specified working directory if it doesn't already exist.
  FileUtils.mkdir_p(DERIVATIVO['working_directory'])
end
