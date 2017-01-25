require 'tempfile'
require 'rmagick'
class V0::ThumbnailsController < ActionController::Base
  DEFAULT_FORMAT = 'image/png'
  DEFAULT_THUMBNAIL_SIZE = 75

  include Magick
  include Derivativo::V0::UploadInfo
  include Derivativo::RequestTokenAuthentication

  def create
    unless (status = authenticate_request_token) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    
    # read the POSTed content into a tempfile
    Rails.logger.info "received #{upload_original_filename} of #{upload_original_format}"
    src_ext = file_extension_for_format(upload_original_format)
    Tempfile.open([upload_original_filename, '.' + src_ext]) do |f|
      open(f.path, 'w+b') do |b|
        Rails.logger.info b.path
        IO.copy_stream(request.body, b)
      end
      # get the long side from the request, or use a default
      format = thumb_format
      ext = file_extension_for_format(format)
      temp_name = File.basename(upload_original_filename, '.' + src_ext) + '.' + ext
      Tempfile.open([temp_name, '.' + ext]) do |f2|
        img = Image.read(f.path).first
        # scale the image down
        thumb = img.scale(long_side.to_i, long_side.to_i)
        Rails.logger.info "thumb.write \"#{f2.path}\""
        thumb.write f2.path
        # stream the content back
        send_file f2.path, :disposition => "inline", filename: temp_name, :content_type => format
      end
    end
  end
  
  def long_side
    request.headers['HTTP_SCALE'] || DEFAULT_THUMBNAIL_SIZE
  end

  def thumb_format
    format = request.headers['HTTP_ACCEPT'] || DEFAULT_FORMAT
    format = format.split(';')[0] if format =~ /;/
    return DEFAULT_FORMAT if format == "image/*"
    return DEFAULT_FORMAT unless format =~ /image\//
    return format
  end
end