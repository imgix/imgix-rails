require "imgix/rails/url_helper"
require "action_view"

class Imgix::Rails::Tag
  include Imgix::Rails::UrlHelper
  include ActionView::Helpers

  def initialize(path, source: nil, tag_options: {}, url_params: {}, srcset_options: {}, attribute_options: {})
    @path = path
    @source = source
    @tag_options = tag_options
    @url_params = url_params
    @srcset_options = srcset_options
    @attribute_options = attribute_options
  end

protected

  def srcset(source: @source, path: @path, url_params: @url_params, srcset_options: @srcset_options, tag_options: @tag_options)
    params = url_params.clone

    width_tolerance = ::Imgix::Rails.config.imgix[:srcset_width_tolerance]
    min_width = @srcset_options[:min_width]
    max_width = @srcset_options[:max_width]
    widths = @srcset_options[:widths]
    disable_variable_quality = @srcset_options[:disable_variable_quality]
    options = { widths: widths, width_tolerance: width_tolerance, min_width: min_width, max_width: max_width, disable_variable_quality: disable_variable_quality}

    ix_image_srcset(@source, @path, params, options)
  end
end
