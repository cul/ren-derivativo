require 'rails_helper'

describe Iiif::Canvas do
  let(:doi) { '10.abc/123' }
  let(:dimensions) { { height: 1024, width: 2048 } }
  let(:route_helper) { double('routes') }
  let(:routing_opts) { Hash.new }
  let(:fedora_pid) { 'iiif:2000' }
  let(:label) { 'Exemplary Canvas' }
  before do
    allow(route_helper).to receive(:iiif_canvas_url).and_return("info://canvas/#{doi}")
    # raster url is necessary for thumbnail
    allow(route_helper).to receive(:iiif_raster_url).and_return("info://raster/#{doi}")
    allow(route_helper).to receive(:iiif_annotation_url).and_return("info://annotation/#{doi}")
    # used in the image annotation
    allow(route_helper).to receive(:iiif_presentation_url).and_return("info://manifest/#{doi}")
    allow(route_helper).to receive(:iiif_id_url).and_return("info://info/#{doi}")
  end
  subject do
    s = Iiif::Canvas.new(doi, routing_opts, route_helper, label)
    s.instance_variable_set(:'@dimensions', dimensions)
    s.instance_variable_set(:'@fedora_pid', fedora_pid)
    s
  end
  # coarsest possible test
  it { subject.to_h }
end