require "rails"
require "rails/railtie"
require "imgix/rails"
require "imgix/rails/url_helper"
require "imgix/rails/view_helper"

module Imgix
  module Rails
    class Railtie < ::Rails::Railtie
      config.imgix = ActiveSupport::OrderedOptions.new

      initializer "imgix-rails.view_helper" do |app|
        Imgix::Rails.configure do |config|
          config.imgix = app.config.imgix
        end

        ActionView::Base.send :include, ViewHelper

        if defined? Sprockets
          Sprockets::Context.send :include, UrlHelper
        end
      end
    end
  end
end
