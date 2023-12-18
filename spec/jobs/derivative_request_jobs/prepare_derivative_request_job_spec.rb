# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DerivativeRequestJobs::PrepareDerivativeRequestJob do
  let(:instance) { described_class.new }

  let(:identifier) { 'test:1' }
  let(:delivery_target) { 'hyacinth2' }
  let(:main_uri) { 'file:///path/to/file.mov' }
  let(:requested_derivatives) { ['access'] }
  let(:access_uri) { 'file:///path/to/file.mp4' }
  let(:poster_uri) { 'file:///path/to/file.tiff' }
  let(:adjust_orientation) { 0 }

  let(:perform_args) do
    {
      identifier: identifier,
      delivery_target: delivery_target,
      main_uri: main_uri,
      requested_derivatives: requested_derivatives,
      access_uri: access_uri,
      poster_uri: poster_uri,
      adjust_orientation: adjust_orientation
    }
  end

  describe '#perform' do
    let(:derivative_request) { FactoryBot.create(:derivative_request) }

    it 'works as expected when valid arguments are given' do
      expect(DerivativeRequest).to receive(:create!).with(**perform_args).and_return(derivative_request)
      configured_job = instance_double(ActiveJob::ConfiguredJob)
      expect(DerivativeRequestJobs::DerivativeRequestJob).to receive(
        :set
      ).with(queue: Derivativo::Queues::DERIVATIVE_REQUEST_FOR_TYPE_ANY).and_return(configured_job)
      expect(configured_job).to receive(:perform_later).with(derivative_request.id)
      instance.perform(**perform_args)
    end
  end
end
