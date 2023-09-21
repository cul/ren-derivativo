# frozen_string_literal: true

class Derivativo::DeliveryAdapter::Hyacinth2
  private attr_reader :url, :email, :password # TODO: Add support for :request_timeout

  def initialize(delivery_target_config)
    @url = delivery_target_config['url']
    @email = delivery_target_config['email']
    @password = delivery_target_config['password']
  end

  def send_derivative_package(derivative_package, identifier)
    # Upload the tempfile to Hyacinth as an access copy
    conn = ::Faraday.new(url: self.url) do |f|
      f.response :json # decode response bodies as JSON
      f.adapter :net_http # Use the Net::HTTP adapter
      f.request :authorization, :basic, self.email, self.password
      f.request :multipart
    end
    digital_object_update_path = "/digital_objects/#{identifier}.json"
    # TODO: Handle failure response and throw error that extends StandardError
    conn.put(digital_object_update_path, payload_for_derivative_package(derivative_package)) do |request|
      request.headers['Content-Type'] = 'multipart/form-data'
    end
  end

  def payload_for_derivative_package(derivative_package)
    # As part of this payload delivery, tell Hyacinth not to perform future derivative
    # processing because this delivery is in response to a request forderivative processing.
    payload = { digital_object_data_json: { perform_derivative_processing: false }.to_json }
    handle_payload_access_copy(payload, derivative_package)
    handle_payload_poster(payload, derivative_package)
    payload
  end

  def handle_payload_access_copy(payload, derivative_package)
    return unless derivative_package.generated_access_tempfile

    payload['access_copy_file'] = Faraday::Multipart::FilePart.new(
      derivative_package.generated_access_tempfile.path,
      BestType.mime_type.for_file_name(derivative_package.generated_access_tempfile.path),
      File.basename(derivative_package.generated_access_tempfile.path)
    )
  end

  def handle_payload_poster(payload, derivative_package)
    return unless derivative_package.generated_poster_tempfile

    payload['poster_file'] = Faraday::Multipart::FilePart.new(
      derivative_package.generated_poster_tempfile.path,
      BestType.mime_type.for_file_name(derivative_package.generated_poster_tempfile.path),
      File.basename(derivative_package.generated_poster_tempfile.path)
    )
  end
end
