# frozen_string_literal: true

class DerivativeRequest < ApplicationRecord
  DERIVATIVE_TYPE_ACCESS = 'access'
  DERIVATIVE_TYPE_POSTER = 'poster'
  DERIVATIVE_TYPE_FEATURED_REGION = 'featured_region'

  VALID_DERIVATIVE_TYPES = [
    DERIVATIVE_TYPE_ACCESS, DERIVATIVE_TYPE_POSTER, DERIVATIVE_TYPE_FEATURED_REGION
  ].freeze

  enum status: { pending: 0, processing: 1, failure: 2 }
  serialize :requested_derivatives, Array
end
