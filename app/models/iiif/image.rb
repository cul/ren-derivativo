class Iiif::Image
  attr_reader :id, :canvas, :route_helper
  def initialize(canvas, route_helper)
    @canvas = canvas
    @route_helper = route_helper 
  end
  def to_h
    image = IIIF_TEMPLATES['image'].deep_dup
    registrant, doi = canvas.doi.split('/')
    opts = canvas.manifest_routing_opts.merge(registrant: registrant, doi: doi)
    image['@id'] = route_helper.iiif_annotation_url(opts)
    underscore = "#{opts[:registrant]}.#{opts[:doi]}"
    underscore.sub!(/[^A-Za-z0-9]/,'_')
    manifest_opts = {manifest_registrant: opts[:manifest_registrant], manifest_doi: opts[:manifest_doi]}
    image['resource']['@id'] = route_helper.iiif_presentation_url(manifest_opts) + "/res/#{underscore}.jpg"
    image['resource']['service']['@id'] = route_helper.iiif_id_url(id: canvas.fedora_pid)
    image['on'] = canvas.uri
    image
  end
end