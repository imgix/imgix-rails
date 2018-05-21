require "imgix"
require "imgix/rails/image_tag"
require "imgix/rails/picture_tag"

module Imgix
  module Rails
    module ViewHelper
      include UrlHelper

      def ix_image_tag(source, options={})
        Imgix::Rails::ImageTag.new(source, options).render
      end

      def ix_picture_tag(source, picture_tag_options: nil, imgix_default_options: nil, breakpoints: nil)
        Imgix::Rails::PictureTag.new(source, picture_tag_options, imgix_default_options, breakpoints).render
      end
    end
  end
end
