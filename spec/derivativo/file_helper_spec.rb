# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::FileHelper do
  describe '.file_location_to_file_path' do
    let(:existing_file_path) { file_fixture('text.txt').realpath.to_s }

    it 'returns the expected value for a valid-format location to a readable file' do
      expect(described_class.file_location_to_file_path("file://#{existing_file_path}")).to eq(existing_file_path)
    end

    it 'raises an error when given a valid-format location for a non-existent file' do
      expect { described_class.file_location_to_file_path('file:///does/not-exist') }.to raise_error(
        Derivativo::Exceptions::UnreadableFilePath
      )
    end

    it 'raises an error when given an unhandled location format' do
      expect { described_class.file_location_to_file_path('mystery:///what/is/this/protocol') }.to raise_error(
        Derivativo::Exceptions::UnhandledLocationFormat
      )
    end
  end

  describe '.working_directory_temp_file' do
    let(:prefix) { 'prefix' }
    let(:suffix) { '.ext' }

    it 'creates a readable file in the expected directory' do
      described_class.working_directory_temp_file(prefix, suffix) do |tempfile|
        tempfile_path = tempfile.path
        expect(tempfile_path).to start_with(DERIVATIVO['working_directory'])
        expect(File.readable?(tempfile_path)).to eq(true)
        expect(File.directory?(tempfile_path)).to eq(false)
      end
    end

    it 'creates a file with the expected prefix and suffix' do
      described_class.working_directory_temp_file(prefix, suffix) do |tempfile|
        File.basename(tempfile.path).tap do |basename|
          expect(basename).to start_with(prefix)
          expect(basename).to end_with(suffix)
        end
      end
    end

    it 'deletes the temp file after the block ends' do
      file_path = nil
      described_class.working_directory_temp_file(prefix, suffix) do |tempfile|
        file_path = tempfile.path
        expect(File.exist?(file_path)).to eq(true)
      end
      expect(File.exist?(file_path)).to eq(false)
    end

    it 'deletes the temp file after the block ends, even if an error is raised in the block' do
      file_path = nil
      expect {
        described_class.working_directory_temp_file(prefix, suffix) do |tempfile|
          file_path = tempfile.path
          expect(File.exist?(file_path)).to eq(true)
          raise RegexpError, 'Oh no!  An error!'
        end
      }.to raise_error(RegexpError)
      expect(File.exist?(file_path)).to eq(false)
    end
  end

  describe '.working_directory_temp_dir' do
    let(:suffix) { '-dir' }

    it 'creates a readable directory in the expected directory' do
      described_class.working_directory_temp_dir(suffix) do |tempdir|
        tempdir_path = tempdir.path
        expect(tempdir_path).to start_with(DERIVATIVO['working_directory'])
        expect(File.readable?(tempdir_path)).to eq(true)
        expect(File.directory?(tempdir_path)).to eq(true)
      end
    end

    it 'creates a directory with the expected suffix' do
      described_class.working_directory_temp_dir(suffix) do |tempdir|
        expect(File.basename(tempdir.path)).to end_with(suffix)
      end
    end

    it 'deletes the temp directory after the block ends' do
      directory_path = nil
      described_class.working_directory_temp_dir(suffix) do |tempdir|
        directory_path = tempdir.path
        expect(Dir.exist?(directory_path)).to eq(true)
      end
      expect(Dir.exist?(directory_path)).to eq(false)
    end

    it 'deletes the temp directory after the block ends, even if an error is raised in the block' do
      directory_path = nil
      expect {
        described_class.working_directory_temp_dir(suffix) do |tempdir|
          directory_path = tempdir.path
          expect(Dir.exist?(directory_path)).to eq(true)
          raise RegexpError, 'Oh no!  An error!'
        end
      }.to raise_error(RegexpError)
      expect(Dir.exist?(directory_path)).to eq(false)
    end
  end

  describe '.block_until_file_exists' do
    let(:retry_interval) { 1.0 }
    let(:num_retries) { 3 }

    it 'will not sleep for retry_interval, instead returning immediately when the file is found' do
      with_auto_deleting_tempfile('foo', '.txt') do |file|
        start_time = Time.current
        result = described_class.block_until_file_exists(file.path, retry_interval, num_retries)
        expect(Time.current - start_time).to be < retry_interval
        expect(result).to be true
      end
    end

    it "will check max number of times for a file that doesn't exist and will then raise an exception" do
      non_existent_file_path = '/definitely/does/not/exist/25379/25370/file'
      start_time = Time.current
      expect {
        described_class.block_until_file_exists(non_existent_file_path, retry_interval, num_retries)
      }.to raise_error(Derivativo::Exceptions::TimeoutException)
      # add a margin of error to our time comparison to account for minor timing differences in test
      timing_margin_of_error = retry_interval * 0.1
      expect(Time.current - start_time).to be >= ((num_retries * retry_interval) - timing_margin_of_error)
    end
  end
end
