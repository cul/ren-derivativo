module Derivativo::Iiif::Info

  def self.info(id_url:, version:, original_width:, original_height:, scale_factors:, is_restricted_size_image:, restricted_use_image_size:, allowed_sizes:, tile_size:, formats:)
    raise 'Only IIIF version 2 is supported at the moment' unless version.to_s == '2'

    response = {
      "@context" => "http://iiif.io/api/image/2/context.json",
      "@id" => id_url,
      "protocol" => "http://iiif.io/api/image",
      "width" => original_width,
      "height" => original_height,
      "sizes" => iiif_allowed_sizes(original_width, original_height, is_restricted_size_image, DERIVATIVO[:restricted_use_image_size], DERIVATIVO[:sizes]),
      # "maxWidth" => DERIVATIVO[:restricted_use_image_size],
      # "maxHeight" => DERIVATIVO[:restricted_use_image_size],
      "tiles" => [
        {
          "width" => tile_size,
          "scaleFactors" => [scale_factors]
        }
      ],
      "profile" => [
        "http://iiif.io/api/image/2/level2.json",
        {
          "formats" => formats.keys,
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

  def self.iiif_allowed_sizes(original_width, original_height, is_restricted_size_image, restricted_use_image_size, app_allowed_sizes)
    app_allowed_sizes.sort.select{|s| !is_restricted_size_image || s < restricted_use_image_size }.map do |size|
      if original_width.nil? || original_width== 0 || original_height.nil? || original_height == 0
        next {
          width: 0,
          height: 0
        }
      elsif original_width > original_height
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
