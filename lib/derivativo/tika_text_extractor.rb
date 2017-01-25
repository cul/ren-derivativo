require 'addressable/uri'

class Derivativo::TikaTextExtractor

  def self.extract_text_from_file(path_to_file)

    filename = File.basename(path_to_file)

    # Read entire file into memory (since the whole thing needs to get sent tika over http anyway)
    file_content = IO.binread(path_to_file)

    # Send file for content type detection (to improve text extraction accuracy)
    content_type = RestClient.put(DERIVATIVO['tika_url'] + '/detect/stream', file_content, {
        'Content-Type' => 'text/plain',
        'Content-Disposition' => "attachment; filename=#{Addressable::URI.encode(filename)}", # Supply filename for better detection
        'Accept' => 'text/plain' # Expect plain text back (as opposed to text/html or some other format)
      }
    )
    # Send file for text extraction, using content type determined by previous tika request
    fulltext = RestClient.put(DERIVATIVO['tika_url'] + '/tika', file_content, {
        'Content-Type' => content_type,
        'Accept' => 'text/plain' # Expect plain text back (as opposed to text/html or some other format)
      }
    )

    return fulltext

  end

end