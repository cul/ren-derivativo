require 'rails_helper'

describe ResourcesController, :type => :controller do
  before do
    expect(controller).not_to be_nil
    request.env['HTTP_AUTHORIZATION'] = api_key
  end
  describe '#index' do
    let(:api_key) { nil }
    it "does not require an api_key for the index action" do
      get :index
      expect(response.status).to eq(200)
      expect(response.body).to eq('{"api_version":"1.0.0"}')
    end
  end

  describe '#update' do
    subject do
      put :update, params
      response.status
    end
    context 'no api_key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'] + "bad")
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'])
      end
      context 'bad doc id' do
        before do
          allow(ActiveFedora::Base).to receive(:find).
            with('baad:id').
            and_raise(ActiveFedora::ObjectNotFoundError)
        end
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(404) }
      end
      context 'good doc id' do
        before do
          fobj = ActiveFedora::Base.new(pid: 'good:id')
          allow(ActiveFedora::Base).to receive(:find).
            with('good:id').
            and_return(fobj)
          allow(Derivativo::FedoraObjectTypeCheck).to receive(:is_rasterable_generic_resource?).
            and_return(true)
          allow_any_instance_of(IiifResource).to receive(:create_base_derivatives_if_not_exist).
            and_return(nil)
        end
        let(:params) { { id: 'good:id' } }
        it do
          expect(subject).to eql(200)
        end
      end
    end
  end

  describe '#destroy' do
    subject do
      # Mock implementation of DerivativoResource#clear_cache so we don't try to make a call to Fedora for this test
      allow_any_instance_of(DerivativoResource).to receive(:clear_cache).and_return(nil)
      delete :destroy, params
      response.status
    end
    context 'no api_key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'] + "bad")
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'])
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(200) }
      end
      context 'good doc id' do
        let(:params) { { id: 'good:id' } }
        it { is_expected.to eql(200) }
      end
    end
  end

  describe '#destroy_cachable_properties' do
    subject do
      delete :destroy_cachable_properties, params
      response.status
    end
    context 'no api_key' do
      let(:api_key) { nil }
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(401) }
    end
    context 'invalid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'] + "bad")
      end
      let(:params) { { id: 'good:id' } }
      it { is_expected.to eql(403) }
    end
    context 'valid api_key' do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'])
      end
      context 'bad doc id' do
        let(:params) { { id: 'baad:id' } }
        it { is_expected.to eql(200) }
      end
      context 'good doc id' do
        let(:params) { { id: 'good:id' } }
        it { is_expected.to eql(200) }
      end
    end
  end
end
