require "imgix/rails/version"

if defined? Rails::Railtie
  require "imgix/railtie"
end

require "active_support"

module Imgix
  module Rails
    STRATEGIES = [:crc, :cycle]
    class Config < ::ActiveSupport::OrderedOptions; end

    def self.config
      @@config ||= Config.new
    end

    def self.configure
      yield self.config
    end
  end
end
