require 'rails_helper'

describe Derivativo::PdfDerivatives, :type => :unit do
  let(:klass) { Class.new { include Derivativo::PdfDerivatives } }
  let(:instance) { klass.new }

  context "#percentage_compression_for_file_size" do
    let(:sizes_to_compression_percentages) do
      {
        1 => 100,
        30 => 45,
        100 => 25,
        200 => 18,
        300 => 16,
        400 => 14,
        500 => 13,
        600 => 12,
        700 => 12,
        800 => 11,
        900 => 11,
        1000 => 11,
        2000 => 9,
        10000 => 8,
        100000 => 8
      }
    end
    it "returns the expected percentages" do
      expect(
        sizes_to_compression_percentages.map do |file_size_in_mb, compression_percentage|
          [file_size_in_mb, instance.percentage_compression_for_file_size(file_size_in_mb)]
        end.to_h
      ).to eq(sizes_to_compression_percentages)
    end
  end
end
