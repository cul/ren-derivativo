# frozen_string_literal: true

class DerivativeRequestJobs::DerivativeRequestJob < ApplicationJob
  queue_as Derivativo::Queues::DERIVATIVE_REQUEST_FOR_TYPE_ANY

  # Generates the access copy, base copy, and specific raster for the given resource.
  # Does not regenerate the access, base, or raster if they already exist.
  # If raster_opts is given a value of nil, specific raster generation will be skipped
  # and only access and base generation will occur.
  def perform(derivative_request_id)
    derivative_request = DerivativeRequest.find(derivative_request_id)

    derivative_request.with_lock do
      # This job should only run for pending DerivativeRequests. If this DerivativeRequest
      # is anything other than pending, then we will immediately return
      return unless derivative_request.pending?

      # Set status to processing
      derivative_request.update!(status: :processing)
    end

    derivative_package = Derivativo::DerivativePackage.new(
      requested_derivatives: derivative_request.requested_derivatives,
      main_uri: derivative_request.main_uri,
      access_uri: derivative_request.access_uri,
      poster_uri: derivative_request.poster_uri
    )
    derivative_package.generate

    # TODO: Send completed derivative package content to Hyacinth
    Derivativo::DeliveryAdapter.for(derivative_request.delivery_target).send_derivative_package(
      derivative_package, derivative_request.identifier
    )

    # If we got here, the resource can be destroyed because processing is complete. We don't change
    # the status to "done".  We just destroy the resource because it is no longer needed.
    derivative_request.destroy!
  rescue StandardError, SyntaxError => e
    # NOTE: An uncaught SyntaxError in later-called code would result in a derivative_request
    # that's incorrectly stuck with a "processing" status, so that's why we catch (and re-throw)
    # SyntaxErrors in this block too.
    handle_and_rethrow_unexpected_error(derivative_request, e)
  ensure
    # Always clean up the derivative package, otherwise we may leave temp files on the filesystem.
    derivative_package.delete if defined?(derivative_package) && derivative_package
  end

  def handle_and_rethrow_unexpected_error(derivative_request, e)
    derivative_request.update!(
      status: :failure,
      error_message: "#{e.message}\n#{e.backtrace.join("\n\t")}"
    )
    # And re-raise the exception so that we don't hide it
    raise e
  end
end
