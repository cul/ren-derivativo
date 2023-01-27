# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::Iiif::IiifImageSizeRestriction do
  describe '.restricted_use_iiif_size' do
    # subject should always be of format /!?\d+,\d+/
    let(:result) { described_class.restricted_use_iiif_size(size, region, original, max) }
    subject { result }
    let(:original) { Derivativo::Iiif::IiifImageSizeRestriction::Area.new(1200, 1000) }
    let(:max) { Derivativo::Iiif::IiifImageSizeRestriction::Size.new(800, 800).best_fit!(true) }

    context "should throw an error when given a 'featured' region because 'featured' regions are not resized based on restriction status" do
      let(:size) { 'full' }
      let(:region) { 'featured' }
      it { expect{ subject }.to raise_error(Derivativo::Exceptions::UnsupportedRegionError) }
    end

    context 'named region full, full size' do
      let(:size) { 'full' }
      let(:region) { 'full' }
      it { is_expected.to eql('!800,800') }
    end
    context 'named region full, max size' do
      let(:size) { 'max' }
      let(:region) { 'full' }
      it { is_expected.to eql('!800,800') }
    end
    context 'named region full, 800 width' do
      let(:size) { '800,' }
      let(:region) { 'full' }
      it { is_expected.to eql('!800,666') }
    end
    context 'named region full, unauthorized width' do
      let(:size) { '805,' }
      let(:region) { 'full' }
      it { is_expected.to eql('!800,666') }
    end
    context 'named region full, 800 height' do
      let(:size) { ',800' }
      let(:region) { 'full' }
      it { is_expected.to eql('!800,666') }
    end
    context 'named region full, unauthorized height' do
      let(:size) { ',805' }
      let(:region) { 'full' }
      it { is_expected.to eql('!800,666') }
    end
    context 'region in excess of pixel dimensions' do
      let(:region) { '0,0,1205,1005' }
      context 'size as percentage' do
        let(:size) { 'pct:100' }
        it { is_expected.to eql('800,666') }
      end
      context 'named size' do
        let(:size) { 'full' }
        it { is_expected.to eql('!800,666') }
      end
    end
    context 'region could build in excess of allowable dimensions' do
      context 'with an allowable size' do
        let(:region) { '5,5,800,800' }
        context 'given as percentage' do
          let(:size) { 'pct:100' }
          it { is_expected.to eql('533,533') }
        end
        context 'named' do
          let(:size) { 'full' }
          it { is_expected.to eql('!533,533') }
        end
      end
      context 'with a disallowed size' do
        let(:region) { '5,5,805,805' }
        context 'given as percentage' do
          let(:size) { 'pct:100' }
          it { is_expected.to eql('536,536') }
        end
        context 'named' do
          let(:size) { 'full' }
          it { is_expected.to eql('!536,536') }
        end
      end
    end
    context 'non-numeric, non-keyword size' do
      let(:size) { 'max_effective_height' }
      let(:region) { 'full' }
      subject { }
      it { expect {result}.to raise_error("Invalid IIIF size format: #{size}") }
    end
    context 'explicit zero dimension' do
      let(:region) { 'full' }
      subject { }
      { 'width' => '0,800', 'height' => '800,0' }.each_pair do |dim, param|
        context "at #{dim}" do
          let(:size) { param }
          it { expect {result}.to raise_error("Invalid IIIF size format: #{size}") }
        end
      end
    end
  end
  describe Derivativo::Iiif::IiifImageSizeRestriction::Size do
    {'0' => 0, '100' => 1, '57' => (57/100.0), '57.4' => 574/1000.0}.each_pair do |input, output|
      context do
        subject { described_class.send :to_percent, input }
        it { is_expected.to eql(output) }
      end
    end
  end
end
