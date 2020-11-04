require "imgix/rails/tag"

class Imgix::Rails::ImageTag < Imgix::Rails::Tag

  def render
    url = ix_image_url(@source, @path, @url_params)

    if @lazy
      @tag_options[:data] ||= {}
      @tag_options[:data][:srcset] = srcset
      @tag_options[:data][:sizes] ||= '100vw'
      @tag_options[:data][:src] = url
      image_tag(lazy_url, @tag_options)
    else
      @tag_options[:sizes] ||= '100vw'
      @tag_options[:srcset] = srcset
      image_tag(url, @tag_options)
    end
  end

  private

  def lazy_url
    if @lazy == true
      "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs="
    else
      @lazy
    end
  end
end
