# frozen_string_literal: true

require 'rails_helper'

describe Derivativo::UserPathHelper do
  describe '.which' do
    context 'in a unix-like environment' do
      before do
        stub_const('File::PATH_SEPARATOR', ':') # so that texts run properly regardless of OS running them
        allow(described_class).to receive(:path_values).and_return(['/the/first/path', '/the/second/path', '/the/third/path'])
        allow(File).to receive(:executable?).and_return(false) # default negative match case
        allow(File).to receive(:executable?).with('/the/second/path/ffmpeg').and_return(true) # positive match case
        allow(described_class).to receive(:case_sensitive_file_path).and_return(false) # default negative match case
        allow(described_class).to receive(:case_sensitive_file_path).with('/the/second/path', 'ffmpeg').and_return('/the/second/path/ffmpeg') # positive match case
      end
      it 'finds a program on the path' do
        expect(described_class.which('ffmpeg')).to eq('/the/second/path/ffmpeg')
      end

      context "when a program is not on the path" do
        before do
          allow(described_class).to receive(:case_sensitive_file_path).and_return(nil)
        end
        it 'does not find a program that is not on the path' do
          expect(described_class.which('not_a_real_program')).to eq(nil)
        end
      end
    end

    context 'in a windows environment' do
      before do
        stub_const('File::PATH_SEPARATOR', ';') # so that texts run properly regardless of OS running them
        allow(described_class).to receive(:path_values).and_return(['C:\the\first\path', 'C:\the\second\path', 'C:\the\third\path'])
        allow(described_class).to receive(:pathext_values).and_return(['.CMD', '.EXE', '.BAT'])
        allow(File).to receive(:executable?).and_return(false) # default negative match case
        allow(File).to receive(:executable?).with('C:\the\second\path\ffmpeg.exe').and_return(true) # positive match case
        allow(described_class).to receive(:case_sensitive_file_path).and_return(false) # default negative match case
        allow(described_class).to receive(:case_sensitive_file_path).with('C:\the\second\path', 'ffmpeg.EXE').and_return('C:\the\second\path\ffmpeg.exe') # positive match case
      end
      it 'finds a program on the path' do
        expect(described_class.which('ffmpeg')).to eq('C:\the\second\path\ffmpeg.exe')
      end

      context "when a program is not on the path" do
        before do
          allow(described_class).to receive(:case_sensitive_file_path).and_return(nil)
        end
        it 'does not find a program that is not on the path' do
          expect(described_class.which('not_a_real_program')).to eq(nil)
        end
      end
    end
  end

  describe '.case_sensitive_file_path' do
    let(:existing_file_path) { file_fixture('text.txt').realpath.to_s }
    let(:directory_path) { File.dirname(existing_file_path) }
    let(:upcase_filename) { File.basename(existing_file_path).upcase }

    it 'returns the expected value' do
      expect(described_class.case_sensitive_file_path(directory_path, upcase_filename)).to eq(existing_file_path)
    end

    it 'returns nil when the given directory exists, but the file does not' do
      expect(described_class.case_sensitive_file_path(directory_path, 'does-not-exist')).to eq(nil)
    end

    it 'returns nil when neither the directory does not exist' do
      expect(described_class.case_sensitive_file_path('directory-that-does-not-exist', 'does-not-exist')).to eq(nil)
    end
  end

  describe '.path_values' do
    context 'in a unix-like environment' do
      before do
        stub_const('File::PATH_SEPARATOR', ':') # so that texts run properly regardless of OS running them
        allow(ENV).to receive(:[]).with('PATH').and_return('/the/first/path:/the/second/path:/the/third/path')
      end
      it 'returns the expected values' do
        expect(described_class.path_values).to eq(['/the/first/path', '/the/second/path', '/the/third/path'])
      end
    end

    context 'in a windows-like environment' do
      before do
        stub_const('File::PATH_SEPARATOR', ';') # so that texts run properly regardless of OS running them
        allow(ENV).to receive(:[]).with('PATH').and_return('C:\the\first\path;C:\the\second\path;C:\the\third\path')
      end
      it 'returns the expected values' do
        expect(described_class.path_values).to eq(['C:\the\first\path', 'C:\the\second\path', 'C:\the\third\path'])
      end
    end
  end

  describe '.pathext_values' do
    before do
      stub_const('File::PATH_SEPARATOR', ';') # so that texts run properly regardless of OS running them
      allow(ENV).to receive(:[]).with('PATHEXT').and_return('.CMD;.EXE;.BAT')
    end
    it 'returns the expected values' do
      expect(described_class.pathext_values).to eq(['.CMD', '.EXE', '.BAT'])
    end
  end
end
