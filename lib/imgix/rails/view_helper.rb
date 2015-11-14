require "imgix"
require 'imgix/rails/url_helper'

module Imgix
  module Rails
   module ViewHelper
      include UrlHelper

      def ix_image_tag(source, options={})
        source = replace_hostname(source)
        normal_opts = options.slice!(*available_parameters)

        image_tag(ix_image_url(source, options), normal_opts)
      end

      def ix_responsive_image_tag(source, options={})
        options.merge!({
          srcset: srcset_for(source, options)
        })

        ix_image_tag(source, options)
      end

      def ix_picture_tag(source, options={})
        content_tag(:picture) do
          concat(tag(:source, srcset: srcset_for(source, options)))
          concat(ix_image_tag(source, options))
        end
      end

    private

      def available_parameters
        @available_parameters ||= parameters.keys
      end

      def parameters
        path = File.expand_path("../../../../vendor/parameters.json", __FILE__)
        @parameters ||= JSON.parse(File.read(path), symbolize_names: true)[:parameters]
      end

      def srcset_for(source, options={})
        source = replace_hostname(source)
        configured_resolutions.map do |resolution|
          srcset_options = options.slice(*available_parameters)
          srcset_options[:dpr] = resolution unless resolution == 1
          "#{ix_image_url(source, srcset_options)} #{resolution}x"
        end.join(', ')
      end

      def configured_resolutions
        ::Imgix::Rails.config.imgix[:responsive_resolutions] || [1, 2]
      end
    end
  end
end
