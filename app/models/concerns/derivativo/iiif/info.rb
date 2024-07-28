module Derivativo::Iiif::Info
  extend ActiveSupport::Concern

  def info(id_url, version)
    raise 'Only IIIF version 2 is supported at the moment' unless version.to_s == '2'

    original_width, original_height = get_cachable_property(Derivativo::Iiif::CacheKeys::ORIGINAL_IMAGE_DIMENSIONS_KEY)
    scale_factors = Imogen::Iiif::Tiles.scale_factors_for(original_width, original_height, IiifResource::TILE_SIZE)

    is_restricted_size_image = get_cachable_property(Derivativo::Iiif::CacheKeys::IS_RESTRICTED_SIZE_IMAGE_KEY)

    response = {
      "@context" => "http://iiif.io/api/image/2/context.json",
      "@id" => id_url,
      "protocol" => "http://iiif.io/api/image",
      "width" => original_width,
      "height" => original_height,
      "sizes" => iiif_allowed_sizes(original_width, original_height, is_restricted_size_image, DERIVATIVO[:restricted_use_image_size], DERIVATIVO[:sizes]),
      "tiles" => [
        {
          "width" => IiifResource::TILE_SIZE,
          #"height" => IiifResource::TILE_SIZE,
          "scaleFactors" => scale_factors
        }
      ],
      "profile" => [
        "http://iiif.io/api/image/2/level2.json",
        {
          "formats" => IiifResource::FORMATS.keys,
          "qualities" => [ "default", "gray", "bitonal" ],
        }
      ]
    }

    # If this is a restricted size image, add maxWidth and maxHeight params
    if is_restricted_size_image
      response['maxWidth'] = DERIVATIVO[:restricted_use_image_size]
      response['maxHeight'] = DERIVATIVO[:restricted_use_image_size]
    end

    response
  end

  def iiif_allowed_sizes(original_width, original_height, is_restricted_size_image, restricted_use_image_size, app_allowed_sizes)
    app_allowed_sizes.sort.select{|s| !is_restricted_size_image || s < restricted_use_image_size }.map do |size|
      if original_width > original_height
        next {
          width: size,
          height: (size.to_f * (original_height.to_f/original_width.to_f)).to_i
        }
      else
        next {
          width: (size.to_f * (original_width.to_f/original_height.to_f)).to_i,
          height: size
        }
      end
    end
  end

end
