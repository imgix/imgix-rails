require "imgix"
require "imgix/rails/tag"
require "imgix/rails/image_tag"
require "imgix/rails/picture_tag"

module Imgix
  module Rails
    module ViewHelper
      include UrlHelper

      def ix_image_tag(*args)
        case args.size
        when 1
          Imgix::Rails::ImageTag.new(args[0]).render
        when 2
          source = args[0]
          options = args[1]
          tag_options = options[:tag_options] || {}
          url_params = options[:url_params] || {}
          widths = options[:widths] || []

          if options.except(:tag_options, :url_params, :widths).length > 0
            ActiveSupport::Deprecation.warn('options Hash is deprecated; use :tag_options, :url_params, :widths instead.')
            tag_options = options.slice!(*Imgix::Rails::Tag.available_parameters).except(:widths)
            url_params = options.slice(*Imgix::Rails::Tag.available_parameters).except(:widths)
          end

          Imgix::Rails::ImageTag.new(source, tag_options: tag_options, url_params: url_params, widths: widths).render
        end
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
