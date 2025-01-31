# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::Conversion::OfficeHelpers do
  describe '.office_convert_to_pdf' do
    context 'for a src office document' do
      let(:src_file_path) { file_fixture('office-doc.doc').realpath.to_s }

      it 'works as expected' do
        with_auto_deleting_tempfile('dst', '.pdf') do |dst_file|
          described_class.office_convert_to_pdf(src_file_path: src_file_path, dst_file_path: dst_file.path)
          expect(File.size(dst_file.path)).to be_positive
          with_auto_deleting_tempfile('tempfile', '.txt') do |text_temp_file|
            Derivativo::Extraction.extract_fulltext(src_file_path: dst_file.path, dst_file_path: text_temp_file.path)
            file_content = File.read(text_temp_file.path)
            expect(file_content).to include('Page 1!')
            expect(file_content).to include('Page 2!')
          end
        end
      end

      it 'only converts the first page when called with `first_page_only: true`' do
        with_auto_deleting_tempfile('dst', '.pdf') do |dst_file|
          described_class.office_convert_to_pdf(
            src_file_path: src_file_path, dst_file_path: dst_file.path, first_page_only: true
          )
          expect(File.size(dst_file.path)).to be_positive
          with_auto_deleting_tempfile('tempfile', '.txt') do |text_temp_file|
            Derivativo::Extraction.extract_fulltext(src_file_path: dst_file.path, dst_file_path: text_temp_file.path)
            file_content = File.read(text_temp_file.path)
            expect(file_content).to include('Page 1!')
            expect(file_content).not_to include('Page 2!')
          end
        end
      end
    end

    context 'for a src text document' do
      let(:src_file_path) { file_fixture('text.txt').realpath.to_s }

      it 'works as expected' do
        with_auto_deleting_tempfile('dst', '.pdf') do |dst_file|
          described_class.office_convert_to_pdf(src_file_path: src_file_path, dst_file_path: dst_file.path)
          expect(File.size(dst_file.path)).to be_positive
        end
      end
    end

    context 'when the converted file is larger than the higher compression threshold' do
      let(:src_file_path) { file_fixture('office-doc.doc').realpath.to_s }
      let(:second_conversion_compression_integer) { 50 }
      let(:soffice_binary_path) { described_class.soffice_binary_path_from_config_or_path }

      before do
        allow(described_class).to receive(:converted_file_size_merits_higher_compression_attempt?).and_return(true)
        allow(described_class).to receive(:compression_value_for_first_try_file_size).and_return(
          second_conversion_compression_integer
        )
      end

      it 'runs compression a total of two times and with a higher compression value the second time' do
        with_auto_deleting_tempfile('dst', '.pdf') do |dst_file|
          expect(described_class).to receive(:office_convert_to_pdf_impl).with(
            src_file_path: src_file_path,
            dst_file_path: dst_file.path,
            soffice_binary_path: soffice_binary_path,
            first_page_only: false
          ).ordered.and_call_original
          expect(described_class).to receive(:office_convert_to_pdf_impl).with(
            src_file_path: src_file_path,
            dst_file_path: dst_file.path,
            soffice_binary_path: soffice_binary_path,
            compression_integer: second_conversion_compression_integer,
            first_page_only: false
          ).ordered.and_call_original
          described_class.office_convert_to_pdf(
            src_file_path: src_file_path, dst_file_path: dst_file.path, first_page_only: false
          )
          expect(File.size(dst_file.path)).to be_positive
        end
      end
    end
  end

  describe '.compression_value_for_first_try_file_size' do
    {
      10.megabytes => 80,
      30.megabytes => 80,
      100.megabytes => 25,
      200.megabytes => 18,
      500.megabytes => 13,
      1000.megabytes => 11,
      2000.megabytes => 9,
      3000.megabytes => 8
    }.each do |file_size, expected_compression_integer|
      it "when given a value of #{file_size}, returns a compression value of #{expected_compression_integer}" do
        expect(described_class.compression_value_for_first_try_file_size(file_size)).to eq(expected_compression_integer)
      end
    end
  end

  describe '.conversion_timeout_for_src_file' do
    let(:path_to_small_file) { '/path/to/small/file.png' }
    let(:path_to_large_file) { '/path/to/LARGE/file.png' }

    before do
      allow(File).to receive(:size).with(path_to_small_file).and_return(1.megabyte)
      allow(File).to receive(:size).with(path_to_large_file).and_return(1.gigabyte)
    end

    it 'uses a shorter timeout for a smaller file' do
      expect(described_class.conversion_timeout_for_src_file(path_to_small_file)).to eq(
        Derivativo::Conversion::OfficeHelpers::SMALL_OFFICE_CONVERSION_DOC_TIMEOUT
      )
    end

    it 'uses a longer timeout for a larger file' do
      expect(described_class.conversion_timeout_for_src_file(path_to_large_file)).to eq(
        Derivativo::Conversion::OfficeHelpers::LARGE_OFFICE_CONVERSION_DOC_TIMEOUT
      )
    end
  end
end
