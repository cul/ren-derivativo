class Manifest < CacheableResource
  DEFAULT_SETTINGS = {
    'filename' => 'manifest.json',
    'mime_type' => 'application/json'
  }
  METS_NS = { 'mets' => 'http://www.loc.gov/METS/' }
  THUMBNAIL_OPTS = {
    version: 2,
    region: 'full',
    size: '!256,256',
    rotation: 0,
    quality: 'native',
    format: 'jpg'
  }
  attr_reader :route_helper
  def initialize(id_or_fedora_obj, route_helper)
    super(id_or_fedora_obj)
    @route_helper = route_helper
  end

  def queue_manifest_generation(queue_name = Derivativo::Queue::HIGH)
    base_url = route_helper.iiif_id_url(id: 'do_not_use', version: THUMBNAIL_OPTS[:version])
    base_url = base_url.split('/')[0...-1].join('/')
    Resque.enqueue_to(queue_name, CreateManifestJob, @id, base_url, Time.now.to_s)
  end

  def settings
    @settings ||= DEFAULT_SETTINGS.merge DERIVATIVO.fetch('manifest_settings', {})
  end

  def directory
    File.join(Derivativo::CachePathBuilder.iiif_path_for_id(@id), 'manifest')
  end

  def filename
    settings['filename']
  end

  def path
    File.join(directory, filename)
  end

  def self.struct_map_to_h(xml, route_helper, routing_opts)
    xml = Nokogiri::XML(xml) unless xml.is_a? Nokogiri::XML::Node
    manifest = IIIF_TEMPLATES['manifest'].deep_dup
    canvases = []
    xml.at_xpath('/mets:structMap', METS_NS).tap do |struct_map|
      range = accumulate_structure(struct_map, canvases, route_helper, routing_opts)
      default_sequence = IIIF_TEMPLATES['sequence'].deep_dup
      default_sequence['canvases'] = canvases.map { |canvas| canvas.to_h }
      default_sequence['label'] = struct_map['LABEL'].to_s
      if IIIF_TEMPLATES['hints'].include? struct_map['TYPE'].to_s
        default_sequence['viewingHint'] = struct_map['TYPE'].to_s
      else
        if canvases.length < 3
          default_sequence['viewingHint'] = 'paged'
        else
          default_sequence['viewingHint'] = 'individuals'
        end
      end
      if IIIF_TEMPLATES['directions'].include? struct_map['DIRECTION'].to_s
        default_sequence['viewingDirection'] = struct_map['DIRECTION'].to_s
      end
      manifest['@id'] = route_helper.iiif_manifest_url(routing_opts)
      manifest['sequences'][0] = default_sequence
      if range.branches.length != 0
        #TODO: structure serialization
      end
      #TODO: 'navDate'
      #TODO: 'metadata'
      #TODO: 'license'
      #TODO: 'attribution'
      #TODO: PDF download at 'rendering' in the manifest
    end
    manifest
  end

  def create_manifest_if_not_exist
    FileUtils.mkdir_p directory
    manifest_processing_file_path = path + '.processing'

    # If progress file exists, return
    return if File.exists?(manifest_processing_file_path)

    # Touch file to block concurrent processes from trying to create an access copy
    FileUtils.touch manifest_processing_file_path

    begin
      ds = fedora_object.datastreams['structMetadata']
      if ds && !ds.new?
        struct_xml = Nokogiri::XML(ds.content)
        canvases = []
        manifest = Manifest.struct_map_to_h(struct_xml, route_helper, routing_opts)
        # add properties with dependencies external to structMap
        manifest['label'] = fedora_object.label
        thumb_id = IiifResource.new(id: fedora_pid).get_cachable_property(Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_ID_KEY)
        manifest['thumbnail'] = Manifest.canvas_for(thumb_id, route_helper, routing_opts).thumbnail
        open(path, 'w') { |io| io.write(JSON.pretty_generate(manifest)) }
      end
    ensure
      # Remove touched processing file after processing is complete
      FileUtils.rm manifest_processing_file_path
    end

    path
  end

  def routing_opts
    registrant, doi = @id.split('/')
    { manifest_registrant: registrant, manifest_doi: doi } 
  end

  def structMetadata
    ds = @fedora_object.datastreams['structMetadata']
    if ds.new?
      return ''
    else
      return ds.content
    end
  end

  # accumulate divs as iiif constructs, returning the node/range to which they're appended
  def self.accumulate_structure(node, canvases, route_helper, routing_opts, range = Iiif::Range.new)
    divs = node.xpath('mets:div', METS_NS).sort_by { |div| div['ORDER'].to_i }
    divs.each do |div|
      if div['CONTENTIDS'] # canvas, image
        canvas = canvas_for(div['CONTENTIDS'].to_s, route_helper, routing_opts)
        range.canvases << canvas
        canvases << canvas
      else # range
        accumulate_structure(div, canvases, route_helper, routing_opts, range.branch!)
      end
    end
    range
  end

  def self.canvas_for(id, route_helper, routing_opts)
    Iiif::Canvas.new(id, routing_opts, route_helper)
  end
end