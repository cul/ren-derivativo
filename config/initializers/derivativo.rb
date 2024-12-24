# frozen_string_literal: true

# Store version in a constant so that we can refer to it from anywhere without having to
# read the VERSION file in real time.
APP_VERSION = File.read(Rails.root.join('VERSION'))

DERIVATIVO = Rails.application.config_for(:derivativo).deep_symbolize_keys

FFMPEG.ffmpeg_binary = DERIVATIVO['ffmpeg_binary_path'] if DERIVATIVO['ffmpeg_binary_path'].present?
FFMPEG.ffprobe_binary = DERIVATIVO['ffprobe_binary_path'] if DERIVATIVO['ffprobe_binary_path'].present?

# If no working_directory is set, use default tmpdir.
if DERIVATIVO['working_directory'].blank?
  DERIVATIVO['working_directory'] = Dir.tmpdir
else
  # Create user-specified working directory if it doesn't already exist.
  FileUtils.mkdir_p(DERIVATIVO['working_directory'])
end

# Set the TMPDIR ENV variable so that Vips (via Imogen) writes temp files here.
# This defaults to the OS temp directory if not otherwise set, which can be a
# problem if we're on a host that has limited local disk space.
ENV['TMPDIR'] = DERIVATIVO['working_directory']

Rails.application.config.active_job.queue_adapter = :inline if DERIVATIVO['run_queued_jobs_inline']
