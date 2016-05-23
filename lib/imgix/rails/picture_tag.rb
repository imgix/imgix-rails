require "imgix/rails/tag"
require "imgix/rails/image_tag"

class Imgix::Rails::PictureTag < Imgix::Rails::Tag
  include ActionView::Context

  def initialize(source, options, default_options, breakpoints)
    @source = source
    @options = options
    @default_options = default_options
    @breakpoints = breakpoints
  end

  def render
    content_tag(:picture, @options) do
      @breakpoints.each do |media, opts|
        html_opts = opts.except(*self.class.available_parameters)
        html_opts[:media] ||= media
        html_opts[:srcset] ||= srcset(@default_options.clone.merge(opts))


        concat(content_tag(:source, nil, html_opts))
      end

      concat Imgix::Rails::ImageTag.new(@source, @default_options).render
    end
  end
end
