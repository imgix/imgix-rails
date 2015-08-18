require "rails"
require "rails/railtie"
require "imgix/rails"
require "imgix/rails/view_helper"

module Imgix
  module Rails
    class Railtie < Rails::Railtie
      initializer "imgix-rails.view_helper" do
        ActionView::Base.send :include, ViewHelper
      end
    end
  end
end
