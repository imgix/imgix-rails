module Imgix
  module Rails
    class ConfigurationError < StandardError; end

    module UrlHelper
      def ix_image_url(source, options={})
        validate_configuration!

        source = replace_hostname(source)

        imgix_client.path(source).to_url(options).html_safe
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

        unless !imgix.key?(:shard_strategy) || STRATEGIES.include?(imgix[:shard_strategy])
          raise ConfigurationError.new("#{imgix[:shard_strategy]} is not supported")
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

      def hostnames_to_remove
        Array(::Imgix::Rails.config.imgix[:hostname_to_replace] || ::Imgix::Rails.config.imgix[:hostnames_to_replace])
      end

      def imgix_client
        return @imgix_client if @imgix_client
        imgix = ::Imgix::Rails.config.imgix

        opts = {
          library_param: "rails",
          library_version: Imgix::Rails::VERSION,
          use_https: true,
          secure_url_token: imgix[:secure_url_token]
        }

        if imgix[:source].is_a?(String)
          opts[:host] = imgix[:source]
        else
          opts[:hosts] = imgix[:source]
        end

        if imgix.has_key?(:include_library_param)
          opts[:include_library_param] = imgix[:include_library_param]
        end

        if imgix.has_key?(:use_https)
          opts[:use_https] = imgix[:use_https]
        end

        if imgix.has_key?(:shard_strategy)
          opts[:shard_strategy] = imgix[:shard_strategy]
        end

        @imgix_client = ::Imgix::Client.new(opts)
      end
    end
  end
end
