# frozen_string_literal: true

class DerivativeRequestJobs::PrepareDerivativeRequestJob < ApplicationJob
  queue_as Derivativo::Queues::PREPARE_DERIVATIVE_REQUEST

  # Evaluates the given resource and queues a new DerivativeRequestJob on the appropriate queue,
  # based on resource type.
  def perform(
    identifier:, delivery_target:, main_uri:, adjust_orientation:, requested_derivatives:, access_uri: nil, poster_uri: nil
  )
    derivative_request = DerivativeRequest.find_by(identifier: identifier)
    derivative_request&.with_lock do
      # If a DerivativeRequest with this identifier already exists:
      case derivative_request.status
      when 'pending'
        # If it's still pending, we'll append any newly-requested derivatives to the existing request.
        derivative_request.update!(requested_derivatives: derivative_request.requested_derivatives | requested_derivatives)
        # Then immediately return because this job has already been prepared
        return
      when 'processing'
        # If the new request's requested_derivatives are already included by the
        # currently-processing job...that's great!  Nothing more to do here.
        return if (requested_derivatives - derivative_request.requested_derivatives).empty?

        # In the EXTREMELY rare case when a DerivativeRequest is already being processed AND
        # a new DerivativeRequest request with the same resource identifier has arrives that
        # requests a DIFFERENT derivative that is not already included in the currently-processing
        # DerivativeRequest, we will just throw an error (which will be appear in the Resque
        # failed job queue).
        raise Derivativo::Exceptions::ConflictingJobError,
              'Unable to prepare DerivativeRequest because another DerivativeRequest with the '\
              'same resource identifier (but different requested derivatives) is in the middle '\
              'of being processed.  Please wait until the other DerivativeRequest has completed '\
              'processing and try again.'
      else
        # Destroy the record for an already-processed request to allow a new job to be queued for
        # the same identifier.
        # Note: The old request may have completed with an ERROR, and that error will be cleared
        # out by this action, but that's generally fine because if we're re-queueing this record
        # then we're probably re-queuing after fixing an error.
        derivative_request.destroy!
      end
    end

    # Create DerivativeRequest DB record
    derivative_request = ::DerivativeRequest.create!(
      identifier: identifier,
      delivery_target: delivery_target,
      main_uri: main_uri,
      adjust_orientation: adjust_orientation,
      requested_derivatives: requested_derivatives,
      access_uri: access_uri,
      poster_uri: poster_uri
    )

    # For now, queue all requests on single, generic queue. Later on, we'll look at the
    # main's file type and assign a queue based on extension (image, video, audio, etc.).

    DerivativeRequestJobs::DerivativeRequestJob
      .set(queue: Derivativo::Queues::DERIVATIVE_REQUEST_FOR_TYPE_ANY)
      .perform_later(derivative_request.id)
  rescue ActiveRecord::RecordNotUnique
    # If we run into a unique constraint error, that means that two DerivativeRequests for the same
    # identifier were processed at the same time.  This is fine, and we will silently fail here
    # for whichever one arrived second.
  end
end
