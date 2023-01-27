# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Pages', type: :request do
  describe 'GET /' do
    it 'displays the app version' do
      get '/'
      expect(response.body).to include(APP_VERSION)
    end
  end
end
