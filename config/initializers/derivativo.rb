# frozen_string_literal: true

# Store version in a constant so that we can refer to it from anywhere without having to
# read the VERSION file in real time.
APP_VERSION = File.read(Rails.root.join('VERSION'))

DERIVATIVO = Rails.application.config_for(:derivativo).deep_symbolize_keys

FFMPEG.ffmpeg_binary = DERIVATIVO['ffmpeg_binary_path'] if DERIVATIVO['ffmpeg_binary_path'].present?
FFMPEG.ffprobe_binary = DERIVATIVO['ffprobe_binary_path'] if DERIVATIVO['ffprobe_binary_path'].present?

# If working_directory is not set, default to ruby temp dir
if DERIVATIVO['working_directory'].blank?
  DERIVATIVO['working_directory'] = File.join(Dir.tmpdir, Rails.application.class.module_parent_name.downcase)
end
# Make working if it does not already exist
FileUtils.mkdir_p(DERIVATIVO['working_directory'])

# If vips_tmp_directory is not set, default to ruby temp dir
if DERIVATIVO['vips_tmp_directory'].blank?
  DERIVATIVO['vips_tmp_directory'] = File.join(Dir.tmpdir, Rails.application.class.module_parent_name.downcase)
end
# Make vips_tmp_directory if it does not already exist
FileUtils.mkdir_p(DERIVATIVO['vips_tmp_directory'])
# Set the TMPDIR ENV variable so that Vips (via Imogen) writes temp files to the vips_tmp_directory.
# This defaults to the OS temp directory if not otherwise set, which can be a
# problem if we're on a host that has limited local disk space.
ENV['TMPDIR'] = DERIVATIVO['vips_tmp_directory']

Rails.application.config.active_job.queue_adapter = :inline if DERIVATIVO['run_queued_jobs_inline']
