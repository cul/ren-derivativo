require 'json'
class Iiif::PresentationsController < ApplicationController
  def show
    redirect_to iiif_manifest_url(id: params[:id], version: 2), status: 302
  end

  def manifest
    cors_headers
    manifest = Manifest.new(params[:id], self)
    path = manifest.create_manifest_if_not_exist
    respond_to do |fmt|
      fmt.json do
        response.headers['Content-Length'] = File.size(path).to_s
        send_file(path, :filename => "manifest.#{params[:format]}", :content_type => IiifResource::FORMATS[params[:format].to_s])
      end
    end
  end

  def range
    #TODO: Support dereferenceable range constructs
  end

  def canvas
    cors_headers
    data = IIIF_TEMPLATES['canvas'].deep_dup
    respond_to do |fmt|
      fmt.json do
        manifest = Manifest.new(params[:presentation_id], self)
        opts = { presentation_id: params[:presentation_id], id: params[:id] }
        canvas = manifest.canvas_for(opts).to_h
        canvas["@context"] = "http://iiif.io/api/presentation/2/context.json"
        send_data JSON.pretty_generate(canvas)
      end
    end
  end

  def annotation
    #TODO: Support dereferenceable image constructs
  end

  def collection
    #TODO: Support collections
  end

  def cors_headers
    # CORS support: Any site should be able to do a cross-domain info request
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Content-Type'] = 'application/ld+json'
  end
end