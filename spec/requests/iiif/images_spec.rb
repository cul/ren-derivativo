# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Iiif::Images Controller Requests', type: :request do
  let(:resource_id) { 'cul:t4b8gthwjk' }

  describe 'GET /iiif/2/:id' do
    it 'redirects to the expected url' do
      get "/iiif/2/#{resource_id}"
      expect(response).to redirect_to("/iiif/2/#{resource_id}/info.json")
    end
  end

  describe 'GET /iiif/2/:id/info.json' do
    it 'returns the expected response' do
      get "/iiif/2/#{resource_id}/info.json"
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end
  end

  describe 'GET /iiif/:id/:region/:size/:rotation/:quality.:format' do
    it 'returns the expected response' do
      get "/iiif/2/#{resource_id}/full/!800,800/0/native.jpg"
      expect(response.body).to eq('raster') # this is just a placeholder test
    end
  end
end
