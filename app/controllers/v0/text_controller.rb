class V0::TextController < ActionController::Base
  include Derivativo::V0::UploadInfo
  include Derivativo::RequestTokenAuthentication

  def create
    unless (status = authenticate_request_token) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    Rails.logger.info "Received #{upload_original_filename} of #{upload_original_format}"
    
    Tempfile.open([upload_original_filename, '.' + src_ext]) do |tempfile|
      File.open(tempfile.path, 'wb') do |b|
        Rails.logger.info b.path
        IO.copy_stream(request.body, b)
      end
      
      file_size = File.size(tempfile)
      if file_size > DERIVATIVO['tika_max_file_size']
        render status: 500, json: {"error" => "Uploaded file exceeded max allowed text extraction file size of #{DERIVATIVO['tika_max_file_size']} bytes"} #TODO: Is 500 the right status to return?
        return
      else
        extracted_text = Derivativo::TikaTextExtractor.extract_text_from_file(tempfile)
        render :text => extracted_text, :status => 202
      end
    end
  end
end