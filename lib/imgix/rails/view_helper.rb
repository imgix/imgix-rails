require "imgix"
require "imgix/rails/tag"
require "imgix/rails/image_tag"
require "imgix/rails/picture_tag"

module Imgix
  module Rails
    module ViewHelper
      include UrlHelper

      def ix_image_tag(source, tag_options: {}, url_params: {}, widths: [])
        Imgix::Rails::ImageTag.new(source, tag_options: tag_options, url_params: url_params, widths: widths).render
      end

      def ix_picture_tag(source, picture_tag_options: {}, imgix_default_options: {}, breakpoints:, tag_options: {}, url_params: {})
        if picture_tag_options.length > 0
          ActiveSupport::Deprecation.warn('picture_tag_options is deprecated; use tag_options instead.')
          tag_options = picture_tag_options
        end
        if imgix_default_options.length > 0
          ActiveSupport::Deprecation.warn('imgix_default_options is deprecated; use url_params instead.')
          url_params = imgix_default_options
        end
        Imgix::Rails::PictureTag.new(source, tag_options: tag_options, url_params: url_params, breakpoints: breakpoints).render
      end
    end
  end
end
