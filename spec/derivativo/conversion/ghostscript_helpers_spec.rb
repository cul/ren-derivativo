# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::Conversion::GhostscriptHelpers do
  let(:src_file_path) { file_fixture('pdf.pdf').realpath.to_s }

  describe '.ghostscript_convert_pdf_to_pdf' do
    it 'works as expected' do
      with_auto_deleting_tempfile('dst', '.pdf') do |dst_file|
        described_class.ghostscript_convert_pdf_to_pdf(src_file_path: src_file_path, dst_file_path: dst_file.path)
        expect(File.size(dst_file.path)).to be_positive
      end
    end
  end

  describe '.ghostscript_pdf_to_image' do
    it 'works as expected' do
      with_auto_deleting_tempfile('dst', '.png') do |dst_file|
        described_class.ghostscript_pdf_to_image(src_file_path: src_file_path, dst_file_path: dst_file.path)
        expect(File.size(dst_file.path)).to be_positive
      end
    end
  end
end
