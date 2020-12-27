# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResourceRequestJobs::ProcessingHelpers do
  let(:klass) { Class.new.tap { |c| c.include described_class } }
  let(:instance) { klass.new }

  describe '#with_shared_error_handling' do
    let(:resource_request_id) { 1 }

    it 'yields with no args' do
      expect { |b| instance.with_shared_error_handling(resource_request_id, &b) }.to yield_with_no_args
    end

    context 'successfully rescued errors' do
      context 'loggable errors' do
        [Faraday::ConnectionFailed].each do |error_class|
          before do
            expect(Rails.logger).to receive(:error)
          end
          context "when an error of type #{error_class} is raised" do
            it 'rescues the error' do
              expect {
                instance.with_shared_error_handling(resource_request_id) { raise error_class, 'Some message' }
              }.not_to raise_error
            end
          end
        end
      end

      context 'errors that notify Hyacinth of failure' do
        before do
          expect(Hyacinth::Client.instance).to receive(:resource_request_failure!).with(resource_request_id, [String])
        end

        [Hyacinth::Client::Exceptions::UnexpectedResponse, Derivativo::Exceptions::OptionError].each do |error_class|
          context "when an error of type #{error_class} is raised" do
            it 'rescues the error' do
              expect {
                instance.with_shared_error_handling(resource_request_id) { raise error_class, 'Some message' }
              }.not_to raise_error
            end
          end
        end
      end
    end

    context 'unhandled errors' do
      it 'does not intercept unhandled errors like ArgumentError' do
        expect {
          instance.with_shared_error_handling(resource_request_id) { raise ArgumentError, 'Unhandled error!' }
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#validate_required_option!' do
    let(:options) { { 'opt1' => 'val1', 'opt2' => 'val2', 'format' => 'png' } }
    let(:key) { 'format' }
    let(:allowed_values) { ['png', 'jpg'] }

    context 'presence of required option' do
      it 'does not raise an error when a required option is present' do
        expect { instance.validate_required_option!(options, key) }.not_to raise_error
      end

      context 'when a required option is absent' do
        let(:key) { 'missing_key' }
        it 'raises an error' do
          expect { instance.validate_required_option!(options, key) }.to raise_error(Derivativo::Exceptions::OptionError, "Missing required option: #{key}")
        end
      end
    end

    context 'allowed value for required option' do
      it 'does not raise an error when an allowed value is given' do
        expect { instance.validate_required_option!(options, key, allowed_values) }.not_to raise_error
      end

      context 'when a value is given that is not allowed' do
        let(:allowed_values) { ['gif', 'tiff'] }
        it 'raises an error' do
          expect {
            instance.validate_required_option!(options, key, allowed_values)
          }.to raise_error(Derivativo::Exceptions::OptionError, "Value png is not allowed for option #{key}. Must be one of: #{allowed_values.join(', ')}")
        end
      end
    end
  end
end
