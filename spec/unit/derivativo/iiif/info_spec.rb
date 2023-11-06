require 'rails_helper'

describe Derivativo::Iiif::Info do

  describe ".info" do
    let(:iiif_resource) { IiifResource.new(id: 'cul:1234567') }
    let(:id_url) { 'http://localhost:5000/iiif/2/cul:1234567/info.json' }
    let(:version) { '2' }
    let(:known_width) { 3600 }
    let(:known_height) { 4770 }
    let(:result) { iiif_resource.info(id_url, version) }

    before do
      allow(iiif_resource).to receive(:get_cachable_property).with(
        Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY
      ).and_return([known_width, known_height])
      allow(iiif_resource).to receive(:get_cachable_property).with(
        Derivativo::Iiif::CacheKeys::IS_RESTRICTED_SIZE_IMAGE_KEY
      ).and_return(false)
    end

    let(:expected) do
      {
        '@context' => 'http://iiif.io/api/image/2/context.json',
        '@id' => id_url,
        'protocol' => 'http://iiif.io/api/image',
        'width' => known_width,
        'height' => known_height,
        'sizes' => [{height: 256, width: 193}, {height: 512, width: 386}, {height: 1024, width: 772}, {height: 1280, width: 966}],
        'tiles' => [{'scaleFactors' => [1, 2, 4, 8, 16, 32], 'width' => 512, 'height' => 512}],
        'profile' => [
          'http://iiif.io/api/image/2/level2.json',
          {
            'formats' => ['jpg', 'png'],
            'qualities' => ['default', 'gray', 'bitonal']
          }
        ],
      }
    end

    it 'returns the expected value' do
      expect(result).to eq(expected)
    end
  end
end
