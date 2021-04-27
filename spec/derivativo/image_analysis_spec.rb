# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::ImageAnalysis do
  describe ".featured_thumbnail_region" do
    let(:src_file_path) { file_fixture('image.jpg').realpath.to_s }

    let(:left_x) { 10 }
    let(:top_y) { 5 }
    let(:right_x) { 20 }
    let(:bottom_y) { 15 }
    # Stub the get method so that we get a consistent value back for testing
    before { allow(Imogen::Iiif::Region::Featured).to receive(:get).and_return([left_x, top_y, right_x, bottom_y]) }

    it 'performs the correct math operations on the value returned by internal method Imogen::Iiif::Region::Featured.get' do
      expect(described_class.featured_thumbnail_region(src_file_path: src_file_path)).to eq('10,5,10,10')
    end
  end
end
