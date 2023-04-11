# frozen_string_literal: true

class Iiif::ImagesController < ApplicationController
  # NOTE: We're allowing CORS on the raster action so that browser clients can bust the browser
  # cache for a specific resource using fetch with {cache: 'reload'}.
  before_action :enable_cors, only: [:iiif_id, :info, :raster]

  # GET /iiif/2/:id
  def iiif_id
    # The id url route just redirects to info url route for that id
    redirect_to iiif_info_url(id: params[:id], format: :json, version: params[:version]), status: :found
  end

  # GET /iiif/2/:id/info.json
  def info
    resource = Resource.new(info_params[:id])

    # If the base is not available, that means we can't get width or height information for the
    # response in this controller action.
    if !resource.base_available?
      PrepareAccessBaseRasterJob.perform_later(identifier: resource.identifier, raster_opts: nil)
      render plain: 'This resource is still being processed.', status: 202
      return
    end

    width, height = resource.base_dimensions
    render json: Derivativo::Iiif::Info.info(
      id_url: iiif_id_url(id: params[:id], version: params[:version]),
      version: params[:version],
      original_width: width,
      original_height: height,
      scale_factors: 1,
      is_restricted_size_image: false,
      restricted_use_image_size: DERIVATIVO[:restricted_use_image_size],
      allowed_sizes: DERIVATIVO[:sizes],
      tile_size: IIIF_TILE_SIZE,
      formats: DERIVATIVO[:allowed_formats]
    )
  end

  # GET /iiif/2/:id/:region/:size/:rotation/:quality.(:format)
  # e.g. /iiif/2/sample/full/full/0/default.png
  def raster
    # Store result of raster_params in local variable raster_opts so we don't re-execute the
    # raster_params method every time we need to read the params. And also extract only required params.
    raster_opts = self.raster_params.slice(:id, :region, :size, :rotation, :quality, :format)

    resource = Resource.new(raster_opts[:id])
    raster_path = resource.raster_path(raster_opts)
    raster_exists = File.exist?(raster_path)
    is_public = resource.is_public?
    #resource.cacheable_props.processing = false
    # Simplest case: Raster exists and is publicly available (with no size restrictions)
    if raster_exists && is_public
      send_public_raster(raster_path, params[:download] == 'true', true)
      return
    end

    allowed_file_extensions = DERIVATIVO[:allowed_formats].keys
    if !DERIVATIVO[:allowed_formats].keys.include?(raster_opts[:format])
      render plain: "Invalid file extension. Must be one of: #{allowed_file_extensions}", status: 400
      return
    end

    if resource.cacheable_props.processing
      # Redirect to placeholder because there's nothing else available to serve right now.
      redirect_to ({}.merge(params.to_unsafe_h).merge(id: 'placeholder:unavailable')), status: 302
      return
    end

    # There are some resource types that we cannot extract images from (example: ISO files). In those cases,
    # we have assigned specific placeholder images to these resources, so we will will serve the specific placeholder.
    placeholder_image = resource.cacheable_props.use_placeholder_image
    if placeholder_image.present?
      redirect_to ({}.merge(params.to_unsafe_h).merge(id: "placeholder:#{placeholder_image}")), status: 302
      return
    end

    # Check if a base is available.  If not, we'll serve a placeholder image and queue background
    # generation of the access copy (if needed), the base, and the requested raster.
    if !resource.base_available?
      PrepareAccessBaseRasterJob.perform_later(
        identifier: resource.identifier,
        raster_opts: raster_opts,
      )

      # Redirect to placeholder because there's nothing else available to serve right now.
      redirect_to ({}.merge(params.to_unsafe_h).merge(id: 'placeholder:unavailable')), status: 302
      return
    end

    # If we got here, we DO have a base available.  This also means that we have the width and height
    # of the base available.  Based on the user's raster params and the base width and height, let's
    # check if the user is allowed to view the level of image quality they are requesting.
    # If not, we'll return a 403 status.
    if !requested_raster_allowed_for_non_public_resource(
      resource.cacheable_props.base_width,
      resource.cacheable_props.base_height,
      raster_opts,
      DERIVATIVO[:restricted_use_image_size]
    )
      render plain: 'Requested raster not available', status: 403
    end

    # If we got here, we have a base available AND the user is allowed to receive the raster
    # they are requesting.  Let's generate and send this raster.

    # # The absence of base_width and base_height means that we DON'T have a base image available.
    # # But the presence of both is not a guarantee that we DO have a base image available – it could
    # # have been deleted from the filesystem after the width and height caches were generated.
    # # So we'll check if the base exists.
    # base_cache_path = resource.base_cache_path
    # base_cache_exists = File.exist?(base_cache_path)

    # if !base_cache_exists
    #   GenerateRasterJob.perform_later(
    #     identifier: resource.identifier,
    #     raster_opts: raster_opts,
    #     generate_base_if_not_exist: true
    #   )
    #   redirect_to ({}.merge(params.to_unsafe_h).merge(id: 'placeholder:file')), status: 302
    #   return
    # end

    # If we got here, then that means that we have a base image available, and the user has
    # requested a raster that they have permission to view, but the raster does not exist yet.
    # So we'll generate the raster on the fly, right now, and return it to the user.
    resource.generate_raster(raster_opts, false)

    # Send the newly-generated image
    # cache headers depend on whether resource is public
    send_public_raster(raster_path, params[:download] == 'true', is_public)
  end

  private

  def send_public_raster(file_path, force_download, is_public)
    disposition = force_download ? 'attachment' : 'inline'

    # Only set long cache headers for public rasters
    expires_in 1.day, public: true if is_public

    file_extension = File.extname(file_path)
    file_params = {
      disposition: disposition, filename: "image.#{file_extension}",
      content_type: BestType.mime_type.for_file_name(file_path)
    }
    response['Content-Length'] = File.size(file_path).to_s
    send_file(file_path, file_params)
  end

  def enable_cors
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  def requested_raster_allowed_for_non_public_resource(base_width, base_height, raster_opts, max_allowed_full_size)
    requested_size, allowed_size  = Derivativo::Iiif::ImageSizeRestriction.restricted_use_iiif_size(
      raster_opts[:size],
      raster_opts[:region],
      Derivativo::Iiif::ImageSizeRestriction::Area.new(base_width, base_height),
      Derivativo::Iiif::ImageSizeRestriction::Size.new(max_allowed_full_size, max_allowed_full_size).best_fit!(true).freeze
    )

    #puts "requested_size: #{requested_size.inspect}"
    #puts "allowed_size: #{allowed_size.inspect}"

    return requested_size <= allowed_size
  end

  def raster_params
    params.permit(:version, :id, :region, :size, :rotation, :quality, :format)
  end

  def info_params
    params.permit(:version, :id)
  end
end
