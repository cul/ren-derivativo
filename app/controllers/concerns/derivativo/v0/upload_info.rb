require 'mime/types'
# Mixin for retrieving info about an uploaded file
module Derivativo::V0::UploadInfo
  extend ActiveSupport::Concern

  def file_extension_for_format(format)
    MIME::Types[format].first.extensions.first
  end

  def upload_original_format
    @original_format ||=
      request.headers['HTTP_CONTENT_TYPE'] || MIME::Types.type_for(upload_original_filename).first
  end

  def upload_original_filename
    @original_filename ||= begin
      if request.headers['HTTP_CONTENT_DISPOSITION'] &&
        request.headers['HTTP_CONTENT_DISPOSITION'] =~ /filename/
        filename = request.headers['HTTP_CONTENT_DISPOSITION'].split("filename=")[1]
        if filename
          filename.sub!(/^"/,'')
          filename.sub!(/"$/,'')
          filename
        else
          "temp"
        end
      else
        "temp"
      end
    end
  end
  
end