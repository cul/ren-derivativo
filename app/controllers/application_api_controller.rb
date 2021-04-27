# frozen_string_literal: true

class ApplicationApiController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  private

    # Returns 406 status if format requested is not json. This method should be used as
    # a before_action callback for any controller actions that only respond to json.
    def ensure_json_request
      return if request.format.blank? || request.format == :json
      head :not_acceptable
    end

    # Renders with an :unauthorized status if no request token is provided, or renders with a
    # :forbidden status if the request uses an invalid request token. This method should be
    # used as a before_action callback for any controller actions that require authorization.
    def authenticate_request_token
      authenticate_or_request_with_http_token do |token, _options|
        ActiveSupport::SecurityUtils.secure_compare(DERIVATIVO['remote_request_api_key'], token)
      end
    end
end
