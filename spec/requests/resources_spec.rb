# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Resources Controller Requests', type: :request do
  let(:resource_id) { 'cul:t4b8gthwjk' }

  describe 'PATCH /resources/:id' do
    it 'returns the expected response' do
      patch "/resources/#{resource_id}"
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end
  end

  describe 'DELETE /resources/:id' do
    it 'returns the expected response' do
      delete "/resources/#{resource_id}"
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end
  end

  describe 'DELETE /resources/:id/destroy_cachable_properties' do
    it 'returns the expected response' do
      delete "/resources/#{resource_id}/destroy_cachable_properties"
      expect(JSON.parse(response.body)).to eq({ 'success' => true })
    end
  end
end
