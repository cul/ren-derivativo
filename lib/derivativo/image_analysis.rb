# frozen_string_literal: true

require 'benchmark'

module Derivativo
  module ImageAnalysis
    def self.auto_detect_featured_region(src_file_path:)
      Rails.logger.debug "Detecting featured thumbnail region for #{src_file_path} ..."
      x = y = width = height = nil
      time = Benchmark.measure do
        Imogen.with_image(src_file_path, { revalidate: true }) do |img|
          # We try to use at least 768 pixels from any image when generating a featured
          # area crop so that we don't unintentionally get a tiny 10px x 10px crop
          # that ends up getting scaled up for users and looks blocky/blurry.
          x, y, width, height = corners_to_x_y_width_height(*Imogen::Iiif::Region::Featured.get(img, 768))
        end
      end
      Rails.logger.debug("Finished detecting featured thumbnail region for file #{src_file_path} in #{time.real} seconds.")
      [x, y, width, height].join(',')
    end

    def self.corners_to_x_y_width_height(left_x, top_y, right_x, bottom_y)
      x = left_x
      y = top_y
      width = right_x - left_x
      height = bottom_y - top_y
      [x, y, width, height]
    end
  end
end
