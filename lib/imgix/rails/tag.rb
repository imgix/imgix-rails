require "imgix/rails/url_helper"

class Imgix::Rails::Tag
  include Imgix::Rails::UrlHelper
  include ActionView::Helpers

  def initialize(path, source: nil, tag_options: {}, url_params: {}, widths: [])
    @path = path
    @source = source
    @tag_options = tag_options
    @url_params = url_params
    @widths = widths
  end

protected

  def srcset(source: @source, path: @path, url_params: @url_params, widths: @widths, tag_options: @tag_options)
    params = url_params.clone
    width_tolerance = ::Imgix::Rails.config.imgix[:srcset_width_tolerance]
    min_width = @tag_options[:min_width]
    max_width = @tag_options[:max_width]
    options = { widths: @widths, width_tolerance: width_tolerance, min_width: min_width, max_width: max_width}

    ix_image_srcset(@source, @path, params, options)
  end
end
