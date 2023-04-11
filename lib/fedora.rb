# frozen_string_literal: true

module Fedora
  CONTENT_DATASTREAM_NAME = 'content'
  SERVICE_DATASTREAM_NAME = 'service'
  ACCESS_DATASTREAM_NAME = 'access'

  EXIF_ORIENTATION_TO_DEGREES = {
    'top-left' => 0,
    'right-top' => 90,
    'left-bottom' => 270,
    'bottom-right' => 180
  }

  WIDTH_PREDICATE = 'http://www.w3.org/2003/12/exif/ns#imageWidth'
  HEIGHT_PREDICATE = 'http://www.w3.org/2003/12/exif/ns#imageLength'

  def self.rubydora_connection
    @rubydora_connection ||= Rubydora.connect(FEDORA_CONFIG)
  end

  def self.find(pid)
    rubydora_connection.find(pid)
  end

  def self.filesystem_path_to_ds_location(path)
    Addressable::URI.encode("file:#{path}").gsub('&', '%26').gsub('#', '%23')
  end

  def self.ds_location_to_filesystem_path(ds_location)
    Addressable::URI.unencode(ds_location).gsub(/^file:\/*/, '/')
  end

  def self.get_orientation_property_if_exist(fobj, fallback_value)
    xml_doc = Nokogiri::XML(fobj.datastreams['RELS-EXT'].content.body)
    xml_doc.remove_namespaces!
    orientation_string = xml_doc.xpath('//orientation').first&.text || 'right-top'
    return EXIF_ORIENTATION_TO_DEGREES.fetch(orientation_string, fallback_value)
  end

  def self.relationship_values_for_predicate(fobj, predicate)
    sparql_query = <<-RELSEXT
      SELECT ?pid FROM <#ri> WHERE {
        <#{fobj.fqpid}> <#{predicate}> ?pid
      }
    RELSEXT
    fobj.repository.sparql(sparql_query).map {|row| row[0]}
  end

  def self.clear_relationship(fobj, predicate)
    relationship_values_for_predicate(fobj, predicate).each do |value|
      fobj.repository.purge_relationship({pid: fobj.pid, predicate: predicate, object: value, isLiteral: true})
    end
  end

  def self.set_width_and_height(fobj, width, height)
    # Replace any existing width and height values with new values
    clear_relationship(fobj, WIDTH_PREDICATE)
    fobj.repository.add_relationship({pid: fobj.pid, predicate: WIDTH_PREDICATE, object: width, isLiteral: true})
    clear_relationship(fobj, HEIGHT_PREDICATE)
    fobj.repository.add_relationship({pid: fobj.pid, predicate: HEIGHT_PREDICATE, object: height, isLiteral: true})
    [width, height]
  end

  # Returns the width and height properties for the object
  # @return [Array] A two-element array of the format: [width, height]
  def self.get_width_and_height(fobj)
    [
      relationship_values_for_predicate(fobj, WIDTH_PREDICATE).first&.to_i,
      relationship_values_for_predicate(fobj, HEIGHT_PREDICATE).first&.to_i
    ]
  end

  def self.with_ds_resource(fobj, ds_id, fedora_content_filesystem_mounted = false)
    ds = fobj.datastreams[ds_id]

    # If the dsLocation starts with the pid, that means that we're dealing with an internally-managed ds,
    # so we can't reference the file directly even if we do have the fedora content filesystem mounted.
    if !ds.dsLocation.start_with?(fobj.pid) && fedora_content_filesystem_mounted
      yield(
        /^file:/.match?(ds.dsLocation) ? ds_location_to_filesystem_path(ds.dsLocation) : ds.dsLocation
      )
    else
      # Since the fedora content filesystem is not mounted, we need to download content over http[s]

      file_name = File.basename(ds.dsLocation.gsub(/^file:/, ''))
      file_extension = File.extname(file_name)
      filename_without_extension = File.basename(file_name, file_extension)

      # In some cases, we actually do want to know the original extension of the file,
      # so we'll preserve it in the temp file filename.
      temp_file = Tempfile.new([filename_without_extension, file_extension])

      internal_uri = "info:fedora/#{fobj.pid}/#{ds_id}"
      begin
        parts = internal_uri.split('/')
        File.open(temp_file.path, 'wb') do |blob|
          rubydora_connection.datastream_dissemination({ dsid: parts[2], pid: parts[1], finished: false }) do |res|
            res.read_body { |seg| blob << seg }
          end
        end
        yield(temp_file.path)
      ensure
        temp_file.unlink
      end
    end
  end

  def self.find_by_itql(query, options = {})
    rubydora_connection.risearch(query, { lang: 'itql' }.merge(options))
  rescue StandardError => e
    logger.error e if defined?(logger)
    '{"results":[]}'
  end

  # Returns the first pid found for the given identifier and raises an exception if more than
  # one pid is found for the given identifier.
  def self.get_pid_for_identifier(identifier)
    results = get_all_pids_for_identifier(identifier)

    raise Derivativo::MultiplePidsFoundForIdentifier if results.length > 1

    results.empty? ? nil : results[0]
  end

  # Returns the pids of ALL objects found with the given identifier
  def self.get_all_pids_for_identifier(identifier)
    find_by_identifier_query = "select $pid from <#ri>
    where $pid <http://purl.org/dc/elements/1.1/identifier> $identifier
    and $identifier <mulgara:is> '#{identifier}'"

    search_response = JSON(
      find_by_itql(
        find_by_identifier_query, { type: 'tuples', format: 'json', limit: '', stream: 'on' }
      )
    )

    return [] if search_response['results'].empty?

    pids_to_return = []
    search_response['results'].each { |result| pids_to_return << result['pid'].gsub('info:fedora/', '') }
    pids_to_return
  end
end
