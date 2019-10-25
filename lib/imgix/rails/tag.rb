require "imgix/rails/url_helper"

class Imgix::Rails::Tag
  include Imgix::Rails::UrlHelper
  include ActionView::Helpers

  def initialize(path, source: nil, tag_options: {}, url_params: {}, widths: [])
    @path = path
    @source = source
    @tag_options = tag_options
    @url_params = url_params
    @widths = widths.length > 0 ? widths : target_widths
  end

protected

  def srcset(url_params: @url_params, widths: @widths)
    if url_params[:w].present?
      warn "Warning: srcset generation will be refactored in the next major release to provide greater flexibility and capabilities in serving responsive images. Unfortunately, these changes will require adjustments to logic that can cause unexpected behavior for users who are using this gem in its current state. Please consult this project's documentation when upgrading to better understand the expected behavior."
    end
    widths = widths || target_widths

    srcset_url_params = url_params.clone
    srcsetvalue = widths.map do |width|
      srcset_url_params[:w] = width

      if url_params[:w].present? && url_params[:h].present?
        srcset_url_params[:h] = (width * (url_params[:h].to_f / url_params[:w])).round
      end

      "#{ix_image_url(@source, @path, srcset_url_params)} #{width}w"
    end.join(', ')
  end

  @@standard_widths = nil

  def compute_standard_widths
    tolerance = ::Imgix::Rails.config.imgix[:srcset_width_tolerance] || SRCSET_TOLERANCE
    prev = MINIMUM_SCREEN_WIDTH
    widths = []
    while prev <= MAXIMUM_SCREEN_WIDTH do
      widths.append(2 * (prev/2).round)   # Ensure widths are even
      prev = prev * (1 + tolerance*2.0)
    end

    widths
  end

  def standard_widths
    return @@standard_widths if @@standard_widths

    @@standard_widths = compute_standard_widths
    @@standard_widths.freeze

    @@standard_widths
  end

private

  MINIMUM_SCREEN_WIDTH = 100
  MAXIMUM_SCREEN_WIDTH = 8192   # Maximum width supported by imgix
  SRCSET_TOLERANCE = 0.08

  # Return the widths to generate given the input `sizes`
  # attribute.
  #
  # @return {Array} An array of {Fixnum} instances representing the unique `srcset` URLs to generate.
  def target_widths
    min_width = @tag_options[:min_width]
    max_width = @tag_options[:max_width]
    if min_width || max_width
      min_width = min_width || MINIMUM_SCREEN_WIDTH
      max_width = max_width || MAXIMUM_SCREEN_WIDTH
      widths = standard_widths.select { |w| min_width <= w && w <= max_width }
    else
      widths = standard_widths
    end

    widths
  end

end
