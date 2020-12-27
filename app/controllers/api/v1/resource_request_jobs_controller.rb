# frozen_string_literal: true

module Api
  module V1
    class ResourceRequestJobsController < ApplicationApiController
      before_action :authenticate_request_token
      before_action :ensure_json_request

      # POST /api/v1/resource_request_jobs.json
      def create
        params_validation_result = Derivativo::ResourceRequestParamsContract.new.call(params.to_unsafe_h)
        if params_validation_result.errors.present?
          error_messages = params_validation_result.errors.map { |e| "#{e.path.join(' => ')} #{e.text}" }
          render json: error_response(error_messages), status: :bad_request
          return
        end
        resource_request_job_params = params_validation_result.to_h[:resource_request_job]

        job_class = job_type_to_class(resource_request_job_params.delete(:job_type))
        job_class.perform_later(resource_request_job_params)
        render json: { result: true }
      rescue Derivativo::Exceptions::InvalidJobType => e
        render json: error_response([e.message]), status: :bad_request
      end

      private

        def error_response(errors)
          { result: false, errors: errors }
        end

        def job_type_to_class(job_type)
          class_name = "ResourceRequestJobs::#{job_type.classify}Job"
          class_name.constantize
        rescue NameError
          basic_error_message = "Job type '#{job_type}' could not be resolved to a job class."
          raise Derivativo::Exceptions::InvalidJobType, basic_error_message
        end
    end
  end
end
