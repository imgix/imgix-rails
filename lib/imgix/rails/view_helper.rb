require "imgix"

module Imgix
  module Rails
    class ConfigurationError < StandardError; end

    module ViewHelper
      def ix_image_url(source, options={})
        validate_configuration!

        source = replace_hostname(source)

        client.path(source).to_url(options).html_safe
      end

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

      def validate_configuration!
        imgix = ::Imgix::Rails.config.imgix
        unless imgix.try(:[], :source)
          raise ConfigurationError.new("imgix source is not configured. Please set config.imgix[:source].")
        end

        unless imgix[:source].is_a?(Array) || imgix[:source].is_a?(String)
          raise ConfigurationError.new("imgix source must be a String or an Array.")
        end
      end

      def replace_hostname(source)
        new_source = source.dup

        # Replace any hostnames configured to trim things down just to their paths.
        # We use split to remove the protocol in the process.
        hostnames_to_remove.each do |hostname|
          splits = source.split(hostname)
          new_source = splits.last if splits.size > 1
        end

        new_source
      end

      def client
        return @imgix_client if @imgix_client
        imgix = ::Imgix::Rails.config.imgix

        opts = {
          host: imgix[:source],
          library_param: "rails",
          library_version: Imgix::Rails::VERSION,
          secure: true
        }

        if imgix[:secure_url_token].present?
          opts[:token] = imgix[:secure_url_token]
        end

        if imgix.has_key?(:include_library_param)
          opts[:include_library_param] = imgix[:include_library_param]
        end

        if imgix.has_key?(:secure)
          opts[:secure] = imgix[:secure]
        end

        @imgix_client = ::Imgix::Client.new(opts)
      end

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

      def hostnames_to_remove
        Array(::Imgix::Rails.config.imgix[:hostname_to_replace] || ::Imgix::Rails.config.imgix[:hostnames_to_replace])
      end
    end
  end
end
