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
    Resque.enqueue_to(queue_name, CreateManifestJob, @id, Time.now.to_s)
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

  def create_manifest_if_not_exist
    FileUtils.mkdir_p directory
    manifest_processing_file_path = path + '.processing'

    # If progress file exists, return
    return if File.exists?(manifest_processing_file_path)

    # Touch file to block concurrent processes from trying to create an access copy
    FileUtils.touch manifest_processing_file_path

    begin
      is_fs_mounted = false # documentary
      fedora_object.datastreams['structMetadata'].tap do |ds|
        struct_xml = Nokogiri::XML(ds.content)
        canvases = []
        struct_xml.xpath('/mets:structMap', METS_NS).each do |struct_map|
          range = accumulate_structure(struct_map, canvases)
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
          manifest = IIIF_TEMPLATES['manifest'].deep_dup
          manifest['@id'] = route_helper.iiif_manifest_url(routing_opts)
          manifest['label'] = fedora_object.label
          manifest['sequences'][0] = default_sequence
          thumb_id = IiifResource.new(id: fedora_pid).get_cachable_property(Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_ID_KEY)
          manifest['thumbnail'] = Canvas.new(thumb_id, routing_opts, route_helper).thumbnail
          if range.branches.length != 0
            #TODO: structure serialization
          end
          #TODO: 'navDate'
          #TODO: 'metadata'
          #TODO: 'license'
          #TODO: 'attribution'
          #TODO: PDF download at 'rendering' in the manifest
          open(path, 'w') { |io| io.write(JSON.pretty_generate(manifest)) }
        end
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
  def accumulate_structure(node, canvases, range = Range.new)
    divs = node.xpath('mets:div', METS_NS).sort_by { |div| div['ORDER'].to_i }
    divs.each do |div|
      if div['CONTENTIDS'] # canvas, image
        canvas = canvas_for(div['CONTENTIDS'].to_s, routing_opts)
        range.canvases << canvas
        canvases << canvas
      else # range
        accumulate_structure(div, canvases, range.branch!)
      end
    end
    range
  end

  def canvas_for(id, opts)
    canvas = Canvas.new(id, opts, route_helper)
    puts canvas.doi.inspect
    registrant, doi = canvas.doi.split('/')
    opts = opts.merge(registrant: registrant, doi: doi)
    image = IIIF_TEMPLATES['image'].deep_dup
    image['@id'] = route_helper.iiif_annotation_url(opts)
    underscore = "#{opts[:registrant]}.#{opts[:doi]}"
    underscore.sub!(/[^A-Za-z0-9]/,'_')
    manifest_opts = {manifest_registrant: opts[:manifest_registrant], manifest_doi: opts[:manifest_doi]}
    image['resource']['@id'] = route_helper.iiif_presentation_url(manifest_opts) + "/res/#{underscore}.jpg"
    image['resource']['service']['@id'] = route_helper.iiif_id_url(id: canvas.fedora_pid)
    image['on'] = canvas.uri
    canvas.image = image
    canvas
  end

  class Canvas < CacheableResource
    attr_reader :uri, :id, :height, :width, :route_helper
    attr_accessor :image, :label

    def initialize(id, manifest_routing_opts, route_helper, label=nil)
      super(id)
      @manifest_routing_opts = manifest_routing_opts
      @label = label
      @route_helper = route_helper
    end

    def uri
      @uri ||= begin
        registrant, doi = self.doi.split('/')
        routing_opts = @manifest_routing_opts.merge(registrant: registrant, doi: doi)
        route_helper.iiif_canvas_url(routing_opts)
      end
    end

    def to_h
      canvas = IIIF_TEMPLATES['canvas'].deep_dup
      canvas['@id'] = uri
      canvas['label'] = label.to_s
      canvas['height'] = dimensions[:height]
      canvas['width'] = dimensions[:width]
      canvas['thumbnail'] = thumbnail
      canvas['images'] = [image] if image
      canvas
    end
    def dimensions
      @dimensions ||= begin
        _dims = IiifResource.new(id: fedora_pid).get_cachable_property(Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY)
        { width: _dims[0].to_i, height: _dims[1].to_i }.freeze
      end
    end
    def thumbnail
      @thumbnail ||= begin
        _props = dimensions.dup
        if _props[:width] > _props[:height]
          _props[:height] = (_props[:height] * 256) / (_props[:width])
          _props[:width] = 256
        else
          _props[:width] = (_props[:width] * 256) / (_props[:height])
          _props[:height] = 256
        end
        _props[:'@type'] = 'dctypes:Image'
        _props[:'@id'] = route_helper.iiif_raster_url(THUMBNAIL_OPTS.merge(id: fedora_pid))
        _props.freeze
      end
    end
  end

  class Range
    attr_reader :prefix, :branches, :canvases
    def initialize(prefix = nil)
      @prefix = prefix
      @branches = []
      @canvases = []
    end
    def to_h
    end
    def branch!
      branch = (branches.length + 1).to_s
      branch = "#{prefix}.#{branch}" unless prefix.blank?
      branches << Range.new(branch)
      branches[-1]
    end
  end
end