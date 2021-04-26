# frozen_string_literal: true

module ResourceRequestJobs
  module ProcessingHelpers
    extend ActiveSupport::Concern

    def with_shared_error_handling(resource_request_id)
      yield
    rescue Faraday::ConnectionFailed => e
      Rails.logger.error("Unable to connect to Hyacinth, so #{self.class.name} for resource request #{resource_request_id} failed. Error message: #{e.message}")
    rescue Faraday::TimeoutError => e
      Rails.logger.error("Connection to Hyacinth timed out, so #{self.class.name} for resource request #{resource_request_id} failed. Error message: #{e.message}")
    rescue Hyacinth::Client::Exceptions::UnexpectedResponse, Derivativo::Exceptions::OptionError => e
      Rails.logger.error("#{self.class.name} for resource request #{resource_request_id} failed. Error message: #{e.message}")
      Hyacinth::Client.instance.resource_request_failure!(resource_request_id, [e.message])
    end

    def validate_required_option!(options, key, allowed_values = nil)
      if (value = options[key]).blank?
        raise Derivativo::Exceptions::OptionError, "Missing required option: #{key}"
      end

      return unless allowed_values.present? && allowed_values.exclude?(value)
      raise Derivativo::Exceptions::OptionError, "Value #{value} is not allowed for option #{key}. Must be one of: #{allowed_values.join(', ')}"
    end
  end
end
