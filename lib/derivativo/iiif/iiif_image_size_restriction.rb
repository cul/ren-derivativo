# frozen_string_literal: true

# Utility class for enabling coercion of requested IIIF canvas size to reduced,
# allowable dimensions if a limit is in place.
class Derivativo::Iiif::IiifImageSizeRestriction
  ABSOLUTE_SIZE = /^(!)?([1-9]\d*)?,([1-9]\d*)?$/

  FULL_REGIONS = %w[full pct:0,0,100,100].freeze
  FULL_SIZES = %w[full max].freeze

  # a rectangle
  class Area
    attr_accessor :w, :h

    def initialize(*params)
      @w = params[0].to_i
      @h = params[1].to_i
    end

    def long_side
      max(w, h)
    end

    def short_side
      min(w, h)
    end

    def dup
      self.class.new(w, h)
    end

    def less_wide_than?(candidate)
      w <= candidate.w
    end

    def less_high_than?(candidate)
      h <= candidate.h
    end

    def fits_in?(candidate)
      less_wide_than?(candidate) && less_high_than?(candidate)
    end

    # if the float is zero or 100 return a FixNum for cleaner math
    def self.to_percent(f)
      f = f.to_f

      return 0 if f.zero? # NOTE: (0.0).zero? evaluates to true
      return 1 if f == 100 # NOTE: (100.0 == 100) evaluates to true

      f / 100
    end

    private_class_method :to_percent

    private

    def max(v1, v2)
      v1 > v2 ? v1 : v2
    end

    def min(v1, v2)
      v1 > v2 ? v2 : v1
    end
  end

  # a rectangle that may be maximum bound
  class Size < Area
    attr_accessor :best_fit

    def dup
      d = self.class.new(w, h)
      d.best_fit = best_fit
      d
    end

    def rescale_to_width!(w, reference)
      self.w = w
      self.h = (w.to_f * reference.h / reference.w).to_i
      self
    end

    def rescale_to_height!(h, reference)
      self.h = h
      self.w = (h.to_f * reference.w / reference.h).to_i
      self
    end

    def default_to_ratio!(original)
      self.w = default_width_for_ratio(original) if w.zero?
      self.h = default_height_for_ratio(original) if h.zero?
      self
    end

    def to_param
      best_fit ? "!#{w},#{h}" : "#{w},#{h}"
    end

    def best_fit!(best_fit)
      self.best_fit = best_fit
      self
    end

    def *(other)
      self.class.new(w * other.w, h * other.h)
    end

    def /(other)
      self.class.new((w.to_f / other.w).to_i, (h.to_f / other.h).to_i)
    end

    def self.from_iiif_param(param, region)
      if FULL_SIZES.include?(param)
        # 'full' and 'max' are similar, though 'max' respects maxWidth and
        # maxHeight. 'full' is deprecated and will be removed in IIIF 3.0
        # For restricted images, we still want to limit size even when 'full'
        # is specified, so we'll treat these as the same thing.
        size = region.to_size(true)
      elsif ABSOLUTE_SIZE.match(param)
        size = absolute_size(param, region)
      elsif param.start_with?('pct:')
        # e.g. 'pct:20' (20% of REGION size, not the original size)
        percent = to_percent(param[4..])
        size = Size.new(region.w * percent, region.h * percent)
      end
      raise "Invalid IIIF size format: #{param}" unless size

      size
    end

    # partial specs maintain aspect ration of region
    def self.absolute_size(size_param, original)
      return unless (m = ABSOLUTE_SIZE.match(size_param)) &&
                    valid_size_parts?(*m[1..3])

      size = Size.new(m[2].to_i, m[3].to_i)
      size.default_to_ratio!(original)
      # Best fit, e.g. '!300,200'. Reduce if > max effective width/height
      size.best_fit = best_fit?(*m[1..3])
      size
    end

    def self.valid_size_parts?(bang, w, h)
      return false if w.blank? && h.blank?
      return (w =~ /[1-9]/) || (h =~ /[1-9]/) if bang.blank?

      (w =~ /[1-9]/) && (h =~ /[1-9]/)
    end

    def self.best_fit?(bang, w, h)
      bang.present? || w.blank? || h.blank?
    end

    private

    def default_width_for_ratio(original)
      (h * (original.w.to_f / original.h)).to_i
    end

    def default_height_for_ratio(original)
      (w * (original.h.to_f / original.w)).to_i
    end
  end

  # a positioned bounding box
  class Region < Area
    attr_accessor :x, :y

    def initialize(*params)
      super
      @x = params[0].to_i
      @y = params[1].to_i
      @w = params[2].to_i
      @h = params[3].to_i
    end

    def dup
      self.class.new(x, y, w, h)
    end

    def relative_to(region)
      dup.relative_to!(region)
    end

    def relative_to!(region)
      move_right! region.x
      move_down! region.y
      self.w = min(w, region.w - x)
      self.h = min(h, region.h - y)
      self
    end

    def move_right!(x)
      self.x += x
    end

    def move_down!(y)
      self.y += y
    end

    def subregion(x, y, w, h)
      self.class.new(x, y, w, h).relative_to!(self)
    end

    def percentage_subregion(x_pct, y_pct, w_pct, h_pct)
      x = (x_pct * w).to_i
      y = (y_pct * h).to_i
      w = (w_pct * w).to_i
      h = (h_pct * h).to_i
      self.class.new(x, y, w, h).relative_to(self)
    end

    def to_size(best_fit = false)
      Size.new(w, h).best_fit!(best_fit)
    end

    def maximum_scaled_size(original_size, max_size)
      (to_size * max_size / original_size).freeze
    end

    def to_param
      "#{x},#{y},#{w},#{h}"
    end

    def self.full(area)
      area.is_a?(Region) ? area.dup : new(0, 0, area.w, area.h)
    end

    # Given a IIIF region param, returns the numeric region width and height
    def self.from_iiif_param(param, original_size)
      return for_name(param, original_size) if FULL_REGIONS.include?(param)

      original = full(original_size)
      if param.start_with?('pct:')
        # pct:x,y,w,h
        to_percent = method[:to_percent]
        original.percentage_subregion(*param[4..].split(',').map(&to_percent))
      else
        # x,y,w,h
        original.subregion(*param.split(',').map(&:to_i))
      end
    end

    def self.for_name(region_param, original_size)
      full(original_size) if FULL_REGIONS.include?(region_param)
    end
  end

  # In order to avoid serving up full images or image slices that are larger
  # than the allowed maximum, we need to determine the maximum effective full
  # region width and height. With an image restriction size of 800, and an
  # original image of 1600x1600, it would be fine to serve up the full region
  # at a resolution of 800x800,but it wouldn't be okay to serve up the top
  # left quarter of the image at 800x800 because that would be an effective
  # resolution of 1600x1600.
  # Note: 'featured' region is not supported by this method, and will raise
  # a Derivativo::Exceptions::UnsupportedRegionError
  def self.restricted_use_iiif_size(size_param, region_param, original, max)
    if region_param == 'featured'
      raise Derivativo::Exceptions::UnsupportedRegionError,
            "Unsupported region: #{region_param}"
    end

    # If the original image is within the restricted use size range, return
    # the originally requested size
    return size_param if original.fits_in?(max)

    # TODO: Do we want to insist on max,max or scale to original ratio?
    return max.to_param if FULL_REGIONS.include?(region_param) && FULL_SIZES.include?(size_param)

    # Determine region width and height in pixels
    region = Region.from_iiif_param(region_param, original)

    size = Size.from_iiif_param(size_param, region)

    self.adjust_size!(original, region, size, max) unless size.fits_in?(region.maximum_scaled_size(original, max))

    size.to_param
  end

  def self.adjust_size!(original, region, size, max)
    max_scaled_for_region = region.maximum_scaled_size(original, max)

    size.rescale_to_width!(max_scaled_for_region.w, region) unless size.less_wide_than?(max_scaled_for_region)

    size.rescale_to_height!(max_scaled_for_region.h, region) unless size.less_high_than?(max_scaled_for_region)

    Rails.logger.warn "adjusted size for policy: #{size.to_param}"
    size
  end
end
