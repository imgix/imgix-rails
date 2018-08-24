require "imgix/rails/tag"

class Imgix::Rails::ImageTag < Imgix::Rails::Tag

  def render
    @tag_options[:srcset] = srcset
    @tag_options[:sizes] ||= '100vw'

    image_tag(ix_image_url(@source, @path, @url_params), @tag_options)
  end
end
