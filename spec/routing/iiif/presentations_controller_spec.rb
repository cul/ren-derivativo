require "rails_helper"

describe Iiif::PresentationsController, type: :routing do
  let(:prefix) { '/iiif/2/presentation' }
  it "routes a DOI to the manifest under the IIIF API version" do
    opts = {}
    opts[:manifest_registrant] = '10.1128'
    opts[:manifest_doi] = "mBio.01326-17"
    opts[:action] = 'manifest'
    opts[:format] = 'json'
    opts[:version] = '2'
    path = "#{prefix}/#{opts[:manifest_registrant]}/#{opts[:manifest_doi]}/manifest.json"
    expect(get: path).to route_to("iiif/presentations#manifest", opts)
  end
  it "routes a nested DOI to the canvas under the IIIF API version" do
    opts = {}
    opts[:registrant] = '10.1128'
    opts[:doi] = "mBio.01326-19"
    opts[:manifest_registrant] = '10.1128'
    opts[:manifest_doi] = "mBio.01326-17"
    opts[:action] = 'canvas'
    opts[:format] = 'json'
    opts[:version] = '2'
    path = "#{prefix}/#{opts[:manifest_registrant]}/#{opts[:manifest_doi]}/canvas/#{opts[:registrant]}/#{opts[:doi]}"
    expect(get: path).to route_to("iiif/presentations#canvas", opts)
  end
end