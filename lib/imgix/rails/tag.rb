require "imgix/rails/url_helper"

class Imgix::Rails::Tag
  include Imgix::Rails::UrlHelper
  include ActionView::Helpers

  @@parameters = nil

  # Store our parameter information on the class instance so that
  # each instance of any this class or our subclasses doesn't have to
  # go back to disk to get this configuration information
  def self.available_parameters
    @@available_parameters ||= parameters.keys
  end

  def self.parameters
    return @@parameters if @@parameters

    path = File.expand_path("../../../../vendor/parameters.json", __FILE__)
    @@parameters ||= JSON.parse(File.read(path), symbolize_names: true)[:parameters]
  end

  def initialize(source, options={})
    @source = source
    @options = options
  end

protected

  def srcset_for(source, options={})
    source = replace_hostname(source)
    configured_resolutions.map do |resolution|
      srcset_options = options.slice(*self.class.available_parameters)
      srcset_options[:dpr] = resolution unless resolution == 1
      "#{ix_image_url(source, srcset_options)} #{resolution}x"
    end.join(', ')
  end

  def configured_resolutions
    ::Imgix::Rails.config.imgix[:responsive_resolutions] || [1, 2]
  end
end