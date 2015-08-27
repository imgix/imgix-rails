module Imgix
  module Rails
    class ConfigurationError < StandardError; end

    module ViewHelper
      def ix_image_tag(source, options={})
        validate_configuration!

        normal_opts = options.slice!(*available_parameters)

        image_tag(client.path(source).to_url(options).html_safe, normal_opts)
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
        imgix = config.imgix
        unless imgix.try(:[], :source)
          raise ConfigurationError.new("imgix source is not configured. Please set config.imgix[:source].")
        end

        unless imgix[:source].is_a?(Array) || imgix[:source].is_a?(String)
          raise ConfigurationError.new("imgix source must be a String or an Array.")
        end
      end

      def client
        return @client if @client

        opts = {
          host: config.imgix[:source],
          library_param: "rails",
          library_version: Imgix::Rails::VERSION
        }

        if config.imgix[:secure_url_token].present?
          opts[:token] = config.imgix[:secure_url_token]
        end

        if config.imgix.has_key?(:include_library_param)
          opts[:include_library_param] = config.imgix[:include_library_param]
        end

        @client = Imgix::Client.new(opts)
      end

      def config
        ::Rails.application.config
      end

      def available_parameters
        @available_parameters ||= parameters.keys
      end

      def parameters
        path = File.expand_path("../../../../vendor/parameters.json", __FILE__)
        @parameters ||= JSON.parse(File.read(path), symbolize_names: true)[:parameters]
      end

      def srcset_for(source, options={})
        configured_resolutions.map do |resolution|
          srcset_options = options.slice(*available_parameters)
          srcset_options[:dpr] = resolution unless resolution == 1
          client.path(source).to_url(srcset_options) + " #{resolution}x"
        end.join(', ')
      end

      def configured_resolutions
        config.imgix[:responsive_resolutions] || [1, 2]
      end
    end
  end
end
