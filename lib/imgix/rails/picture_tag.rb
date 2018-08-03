require "imgix/rails/tag"
require "imgix/rails/image_tag"

class Imgix::Rails::PictureTag < Imgix::Rails::Tag
  include ActionView::Context

  def initialize(source, tag_options: {}, url_params: {}, breakpoints: {}, widths: [])
    @source = source
    @tag_options = tag_options
    @url_params = url_params
    @breakpoints = breakpoints
    @widths = widths.length > 0 ? widths : target_widths
  end

  def render
    content_tag(:picture, @tag_options) do
      @breakpoints.each do |media, opts|
        source_tag_opts = opts[:tag_options] || {}
        source_url_params = opts[:url_params] || {}
        widths = opts[:widths]
        if opts.except(:tag_options, :url_params, :widths).length > 0
          ActiveSupport::Deprecation.warn('use :tag_options, :url_params, :widths instead.')
          source_tag_opts = opts.slice!(*self.class.available_parameters).except(:widths)
          source_url_params = opts.slice(*self.class.available_parameters).except(:widths)
        end

        source_tag_opts[:media] ||= media
        source_tag_opts[:srcset] ||= srcset(url_params: @url_params.clone.merge(source_url_params), widths: widths)
        concat(content_tag(:source, nil, source_tag_opts))
      end

      concat Imgix::Rails::ImageTag.new(@source, url_params: @url_params).render
    end
  end
end
