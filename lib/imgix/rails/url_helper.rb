module Imgix
  module Rails
    class ConfigurationError < StandardError; end

    module UrlHelper
      def ix_image_url(*args)
        validate_configuration!

        case args.size
        when 1
          path = args[0]
          source = nil
          params = {}
        when 2
          if args[0].is_a?(String) && args[1].is_a?(Hash)
            source = nil
            path = args[0]
            params = args[1]
          elsif args[0].is_a?(String) && args[1].is_a?(String)
            source = args[0]
            path = args[1]
            params = {}
          else
            raise RuntimeError.new("path and source must be of type String; params must be of type Hash")
          end
        when 3
          source = args[0]
          path = args[1]
          params = args[2]
        else
          raise RuntimeError.new('path missing')
        end

        imgix_client(source).path(path).to_url(params).html_safe
      end

      protected

      def ix_image_srcset(*args)
        validate_configuration!

        case args.size
        when 1
          path = args[0]
          source = nil
          params = {}
        when 2
          if args[0].is_a?(String) && args[1].is_a?(Hash)
            source = nil
            path = args[0]
            params = args[1]
          elsif args[0].is_a?(String) && args[1].is_a?(String)
            source = args[0]
            path = args[1]
            params = {}
          else
            raise RuntimeError.new("path and source must be of type String; params must be of type Hash")
          end
        when 3
          source = args[0]
          path = args[1]
          params = args[2]
        when 4
          source = args[0]
          path = args[1]
          params = args[2]
          options = args[3]
        else
          raise RuntimeError.new('path missing')
        end
        imgix_client(source).path(path).to_srcset(options: options, **params).html_safe
      end

      private

      def validate_configuration!
        imgix = ::Imgix::Rails.config.imgix

        if imgix.slice(:source, :sources).size != 1
          raise ConfigurationError.new("Exactly one of :source, :sources is required")
        end

        if imgix[:source]
          unless imgix[:source].is_a?(String)
            raise ConfigurationError.new("imgix source must be a String.")
          end
        end

        if imgix[:sources]
          unless imgix[:sources].is_a?(Hash)
            raise ConfigurationError.new(":sources must be a Hash")
          end
        end
      end

      def imgix_client(source)
        begin
          return imgix_clients.fetch(source)
        rescue KeyError
          raise RuntimeError.new("Unknown source '#{source}'")
        end
      end

      def imgix_clients
        return @imgix_clients if @imgix_clients
        imgix = ::Imgix::Rails.config.imgix

        opts = {
          library_param: "rails",
          library_version: Imgix::Rails::VERSION,
          use_https: true,
        }

        if imgix[:source].is_a?(String)
          opts[:domain] = imgix[:source]
        end

        if imgix.has_key?(:include_library_param)
          opts[:include_library_param] = imgix[:include_library_param]
        end

        if imgix.has_key?(:use_https)
          opts[:use_https] = imgix[:use_https]
        end

        sources = imgix[:sources] || { imgix[:source] => imgix[:secure_url_token] }
        @imgix_clients = {}

        sources.map do |source, token|
          opts[:domain] = source
          opts[:secure_url_token] = token
          @imgix_clients[source] = ::Imgix::Client.new(opts)
        end

        default_source = imgix[:default_source] || imgix[:source]
        if default_source
          @imgix_clients[nil] = @imgix_clients.fetch(default_source)
        end

        @imgix_clients
      end
    end
  end
end
