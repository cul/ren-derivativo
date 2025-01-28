# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::Extraction do
  describe '.extract_fulltext' do
    context 'for a src office document' do
      let(:src_file_path) { file_fixture('office-doc.doc').realpath.to_s }

      it 'works as expected' do
        with_auto_deleting_tempfile('dst', '.txt') do |dst_file|
          described_class.extract_fulltext(src_file_path: src_file_path, dst_file_path: dst_file.path)
          expect(File.size(dst_file.path)).to be_positive
          expect(File.read(dst_file.path)).to eq("Page 1!\n\n\nPage 2!\n\n")
        end
      end
    end

    context 'for a plain text document' do
      let(:src_file_path) { file_fixture('text.txt').realpath.to_s }

      it 'works as expected' do
        with_auto_deleting_tempfile('dst', '.txt') do |dst_file|
          described_class.extract_fulltext(src_file_path: src_file_path, dst_file_path: dst_file.path)
          expect(File.size(dst_file.path)).to be_positive
          expect(File.read(dst_file.path)).to eq("It's a text file!\n")
        end
      end
    end
  end
end
