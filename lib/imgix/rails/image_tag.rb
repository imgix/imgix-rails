require "imgix/rails/tag"

class Imgix::Rails::ImageTag < Imgix::Rails::Tag

  def render
    @tag_options[:srcset] = srcset
    @tag_options[:sizes] ||= '100vw'

    @source = replace_hostname(@source)

    image_tag(ix_image_url(@source, @url_params), @tag_options)
  end
end
