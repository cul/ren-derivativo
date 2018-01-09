require 'rails_helper'

describe CreateManifestJob do
  describe '#route_helper' do
    let(:base_url) { 'https://test-server.edu/' }
    subject { described_class.route_helper(base_url) }
    it "should figure out route urls based on a parameter base_url" do
      expect(subject.iiif_id_url(id: 'zoo', version: '2')).to eql(base_url + 'iiif/2/zoo')
    end
  end
end