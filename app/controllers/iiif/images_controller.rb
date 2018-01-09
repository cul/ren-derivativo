class Iiif::ImagesController < ApplicationController
  
  include Derivativo::Iiif::IiifImageSizeRestriction

  def iiif_id
    # id url just redirects to info url for that id
    redirect_to iiif_info_url(id: params[:id], format: :json, version: params[:version]), status: :found
  end

  def info
    # CORS support: Any site should be able to do a cross-domain info request
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Content-Type'] = 'application/ld+json'
    iiif = IiifResource.new(params)
    iiif_info = iiif.info(iiif_id_url(id: params[:id], version: params[:version]), params[:version])
    
    base_derivatives_complete = iiif.base_derivatives_complete?
    if base_derivatives_complete
      # Note: Not doing this for now.  Allowing browser requests to create derivatives on-demand.
      # Immediately pre-cache IIIF slices for this image
      #iiif.create_iiif_slice_pre_cache
    else
      if DERIVATIVO[:queue_long_jobs]
        # Queue base derivatives, set info response 'sizes' to blank, and tell client not to cache this response
        iiif.queue_base_derivatives_if_not_exist(Derivativo::Queue::HIGH)
        iiif_info['sizes'] = []
        expires_now
      else
        iiif.create_base_derivatives_if_not_exist
        base_derivatives_complete = true
      end
    end
    
    expires_in(1.day, public: true) if base_derivatives_complete # TODO: Decide how long we want to cache things on the client side
    render json: iiif_info
  end
  
  def raster
    # Some images have copyright restrictions, so we need to limit the maximum served up size.
    reduce_size_param_if_restricted_image!(params)
    
    # Allow users to request images as downloads
    disposition = params[:download] == 'true' ? 'attachment' : 'inline'
    
    # Only allow approved formats
    unless IiifResource::FORMATS.include? params[:format]
      render :nothing => true, :status => 400
      return
    end
    
    iiif = IiifResource.new(params)
    raster_file_exists = iiif.raster_exists?
    
    unless raster_file_exists
      # No raster was found at the cache path. This could be because:
      # 1) This resource isn't an image and should display a generic file
      #    type placeholder instead. (This is quick to check.)
      # 2) The user is supplying the id for an aggregator object and we
      #    need to serve up a representative image: one of that aggregator's
      #    descendant image resources. (This is quick to check, but we may
      #    need to generate base derivatives for that representative image,
      #    and that can take some time if not queued.)
      # 3) The user is supplying an image resource id for an image that
      #    doesn't yet have a cached raster for the given params. (In this
      #    case, we'll create)
      # 4) The user has supplied an invalid id that isn't associated with
      #    any resource.
      if iiif.has_placeholder_image?
        # Case 1: This resource has a placeholder image.
        # Change params[:id] to the placeholder id.
        params[:id] = 'placeholder:' + iiif.get_cachable_property(Derivativo::Iiif::CacheKeys::PLACEHOLDER_IMAGE_TYPE_KEY)
        iiif = IiifResource.new(params) # Update iiif variable so we can reference it again later with the updated id
        raster_file_exists = iiif.raster_exists?
      elsif iiif.has_representative_resource_id?
        if iiif.get_cachable_property(Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_ID_KEY) != iiif.id
          # Case 2: This resource has a representative image id that is different than its own id.
          # Change params[:id] to the representative id.
          params[:id] = iiif.get_cachable_property(Derivativo::Iiif::CacheKeys::REPRESENTATIVE_RESOURCE_ID_KEY)
          iiif = IiifResource.new(params) # Update iiif variable so we can reference it again later with the updated id
          raster_file_exists = iiif.raster_exists?
        else
          # Case 3: This resource has a representative image that's the same as its own id.
          # This means that we'll need to generate it.
        end
      else
        # Case 4: The given id has no placeholder image and no representative id, which means that it doesn't exist.  Immediately return a 404.
        render :text => 'Resource does not exist.', :status => 404
        return
      end
    end
    
    # Above steps may have generated a raster,
    # so we'll check again to see if the raster exists.
    unless raster_file_exists
      # Queue or create base derivatives if they don't exist
      if iiif.id.start_with?('placeholder:')
        # Always create placeholder images on-demand rather than queueing
        iiif.create_base_derivatives_if_not_exist
      elsif DERIVATIVO[:queue_long_jobs]
        iiif.queue_base_derivatives_if_not_exist(Derivativo::Queue::HIGH)
      else
        iiif.create_base_derivatives_if_not_exist
      end
      
      if iiif.base_derivatives_complete?
        # If base derivatives are complete, then generate the raster immediately
        iiif.create_raster
        raster_file_exists = true
      else
        # If base derivative generation is incomplete, we'll redirect to the 'placeholder:file' image.
        redirect_to ({}.merge(params).merge(id: 'placeholder:file')), status: 302
      end
    end
    
    # If we're here, a raster exists in the cache.  Serve up that raster.
    expires_in 1.day, public: true  # TODO: Decide how long we want to cache things on the client side
    file_params = {
      disposition: disposition, filename: "image.#{params[:format]}",
      content_type: IiifResource::FORMATS[params[:format].to_s]
    }
    response['Content-Length'] = File.size(iiif.raster_cache_path).to_s
    send_file(iiif.raster_cache_path, file_params )
  end
  
  private
  
  def reduce_size_param_if_restricted_image!(parms)
    iiif = IiifResource.new(parms)
    if parms[:region] != 'featured' && iiif.get_cachable_property(Derivativo::Iiif::CacheKeys::IS_RESTRICTED_SIZE_IMAGE_KEY)
      # Reduce user's size param if this is a restricted size image
      original_width, original_height = iiif.get_cachable_property(Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY)
      parms[:size] = restricted_use_iiif_size(
        parms[:size],
        parms[:region],
        Area.new(original_width, original_height),
        Size.new(DERIVATIVO[:restricted_use_image_size],
        DERIVATIVO[:restricted_use_image_size]).best_fit!(true).freeze
      )
    end
  end
  
end
