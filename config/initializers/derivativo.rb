# frozen_string_literal: true

DERIVATIVO = Rails.application.config_for(:derivativo)

# If no working_directory is set, use default tmpdir.
if DERIVATIVO['working_directory'].blank?
  DERIVATIVO['working_directory'] = Dir.tmpdir
else
  # Create user-specified working directory if it doesn't already exist.
  FileUtils.mkdir_p(DERIVATIVO['working_directory'])
end
