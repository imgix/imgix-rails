require "imgix/rails/tag"
require "imgix/rails/image_tag"
require "action_view"

class Imgix::Rails::PictureTag < Imgix::Rails::Tag
  include ActionView::Context

  def initialize(path, source: nil, tag_options: {}, url_params: {}, breakpoints: {}, widths: [])
    @path = path
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
        source_tag_url_params = opts[:url_params] || {}
        widths = opts[:widths]
        unsupported_opts = opts.except(:tag_options, :url_params, :widths)
        if unsupported_opts.length > 0
          raise "'#{unsupported_opts.keys.join("', '")}' key(s) not supported; use tag_options, url_params, widths."
        end

        source_tag_opts[:media] ||= media
        source_tag_opts[:srcset] ||= srcset(url_params: @url_params.clone.merge(source_tag_url_params), widths: widths)
        concat(content_tag(:source, nil, source_tag_opts))
      end

      concat Imgix::Rails::ImageTag.new(@path, source: @source, url_params: @url_params).render
    end
  end
end
