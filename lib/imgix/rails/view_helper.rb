require "imgix"
require "imgix/rails/tag"
require "imgix/rails/image_tag"
require "imgix/rails/picture_tag"

module Imgix
  module Rails
    module ViewHelper
      include UrlHelper

      def ix_image_tag(source=nil, path, tag_options: {}, url_params: {}, widths: [])
        return Imgix::Rails::ImageTag.new(path, source: source, tag_options: tag_options, url_params: url_params, widths: widths).render
      end

      def ix_picture_tag(source=nil, path, tag_options: {}, url_params: {}, breakpoints:)
        return Imgix::Rails::PictureTag.new(path, source: source, tag_options: tag_options, url_params: url_params, breakpoints: breakpoints).render
      end
    end
  end
end
