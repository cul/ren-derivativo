require 'json'
class Iiif::PresentationsController < ApplicationController
  include Derivativo::RequestTokenAuthentication

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  def show
    redirect_to iiif_manifest_url(params), status: 302
  end

  def manifest
    cors_headers
    doi = "#{params[:registrant]}/#{params[:doi]}"
    manifest = Manifest.new(doi, self)
    path = manifest.create_manifest_if_not_exist
    respond_to do |fmt|
      fmt.json do
        response.headers['Content-Length'] = File.size(path).to_s
        send_file(path, :filename => "manifest.#{params[:format]}", :content_type => IiifResource::FORMATS[params[:format].to_s])
      end
    end
  end

  def destroy
    unless (status = authenticate_request_token) == :ok
      render status: status, json: {"error" => "Invalid credentials"}
      return
    end
    doi = "#{params[:registrant]}/#{params[:doi]}"
    manifest = Manifest.new(doi, self)
    File.delete(manifest.path)
    head :no_content
  end

  def range
    #TODO: Support dereferenceable range constructs
  end

  def canvas
    cors_headers
    data = IIIF_TEMPLATES['canvas'].deep_dup
    respond_to do |fmt|
      fmt.json do
        doi = "#{params[:registrant]}/#{params[:doi]}"
        manifest = Manifest.new(doi, self)
        opts = { registrant: params[:registrant], doi: params[:doi], id: params[:id] }
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