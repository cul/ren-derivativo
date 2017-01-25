require 'rails_helper'
require 'base64'
require 'rmagick'

RSpec.describe V0::ThumbnailsController, type: :controller do
  describe "verify_user" do
    let(:good_token) { DERIVATIVO['remote_request_api_key'] }
    let(:bad_token) { 'bad_token' }

    context "authenticated actions" do
      before do
        request.headers['HTTP_AUTHORIZATION'] = "Token token=#{bad_token}"
      end
      it do
        src = File.join(Rails.root,'app/assets/images/placeholders/dark/file.png')
        req_hdrs = {
          'RAW_POST_DATA' => File.open(src, 'rb').read,
          'Content-Type' => "image/png",
          'Content-Disposition' => "attachment; filename=\"queued.png\"",
          'Authorization' => "Token token=#{bad_token}",
          "Accept" => 'image/jpeg'
        }
        request.headers.merge!(req_hdrs)
        response = post :create
        expect(response.status).to eql 403
      end
    end
    context "credentials are valid" do
      let(:token) { DERIVATIVO['remote_request_api_key'] }
      before do
        request.headers['HTTP_AUTHORIZATION'] = "Basic #{good_token}"
      end
      it do
        src = File.join(Rails.root,'app/assets/images/placeholders/dark/file.png')
        req_hdrs = {
          'RAW_POST_DATA' => File.open(src, 'rb').read,
          'Content-Type' => "image/png",
          'Content-Disposition' => "attachment; filename=\"queued.png\"",
          'Authorization' => "Token token=#{good_token}",
          "Accept" => 'image/jpeg',
          'Scale' => "100"
        }
        request.headers.merge!(req_hdrs)
        response = post :create
        #puts response.headers.inspect
        cd = response.headers['Content-Disposition']
        fn = cd.split("filename=")[1]
        fn = fn.split('"')[1]
        Tempfile.open([fn, File.extname(fn).downcase], encoding: 'ascii-8bit') do |tempfile|
          tempfile.write(response.body)
          tempfile.close
          img = Magick::Image.read(tempfile.path).first
          expect(img.base_columns).to eql 100
          expect(img.base_rows).to eql 100
          expect(img.format).to eql 'JPEG'
        end
      end
    end
  end
  describe "upload_original_filename" do
    let (:cd_with_filename) { "attachment; filename=\"testImage.png\"" }
    let (:cd_without_filename) { "attachment" }
    context "with a Content-Disposition header and a filename" do
      before do
        request.headers['HTTP_CONTENT_DISPOSITION'] = cd_with_filename
      end
      it { expect(subject.upload_original_filename).to eql("testImage.png")}
    end
    context "with a Content-Disposition header and no filename" do
      before do
        request.headers['HTTP_CONTENT_DISPOSITION'] = cd_without_filename
      end
      it { expect(subject.upload_original_filename).to eql("temp")}
    end
    context "with no Content-Disposition header" do
      before do
        request.headers['HTTP_CONTENT_DISPOSITION'] = nil
      end
      it { expect(subject.upload_original_filename).to eql("temp")}
    end
  end
end