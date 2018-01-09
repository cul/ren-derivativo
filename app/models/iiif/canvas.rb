class Iiif::Canvas < CacheableResource
  attr_reader :id, :manifest_routing_opts, :route_helper
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
    canvas['images'] = [image_annotation.to_h]
    canvas
  end

  def dimensions
    @dimensions ||= begin
      _dims = IiifResource.new(id: fedora_pid).get_cachable_property(Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY)
      { width: _dims[0].to_i, height: _dims[1].to_i }.freeze
    end
  end

  def image_annotation
    @image ||= Iiif::Image.new(self, route_helper)
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
      _props[:'@id'] = route_helper.iiif_raster_url(Manifest::THUMBNAIL_OPTS.merge(id: fedora_pid))
      _props.freeze
    end
  end
end