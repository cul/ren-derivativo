require 'rails_helper'

describe Derivativo::RequestTokenAuthentication do
  
  controller(ApplicationController) {
    include Derivativo::RequestTokenAuthentication
    def authenticated_action
      render nothing: true, status: authenticate_request_token
    end
  }
  
  before do
    expect(controller).not_to be_nil
    routes.draw do
      get 'authenticated_action' => 'anonymous#authenticated_action'
    end
    request.env['HTTP_AUTHORIZATION'] = api_key
  end
    
  describe '#authenticate_request_token' do
    subject do
      get :authenticated_action
      response.status
    end
    
    context "no token provided" do
      let(:api_key) { nil }
      it { is_expected.to eql(401) }
    end
    
    context "invalid token" do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'] + "bad")
      end
      it { is_expected.to eql(403) }
    end
    context "valid token" do
      let(:api_key) do
        ActionController::HttpAuthentication::Token.encode_credentials(DERIVATIVO['remote_request_api_key'])
      end
      it { is_expected.to eql(200) }
    end
  end
end