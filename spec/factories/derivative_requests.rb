# frozen_string_literal: true

FactoryBot.define do
  factory :derivative_request do
    transient do
      sequence :generated_identifier, 1 do |n|
        "cul:#{n}"
      end
    end

    identifier { generated_identifier }
    requested_derivatives { ['access'] }
    status { 'pending' }
    error_message { nil }
    delivery_target { 'hyacinth2' }
    main_uri { 'file:///path/to/file' }
    access_uri { nil }
    poster_uri { nil }
  end
end
