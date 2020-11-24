require "imgix/rails/tag"

class Imgix::Rails::ImageTag < Imgix::Rails::Tag

  def render
    url = ix_image_url(@source, @path, @url_params)

    if @attribute_options[:srcset].present?
      @tag_options[@attribute_options[:srcset]] = srcset
    else
      @tag_options[:srcset] = srcset
    end

    if @attribute_options[:size].present?
      @tag_options[@attribute_options[:size]] ||= '100vw'
    else
      @tag_options[:sizes] ||= '100vw'
    end

    if @attribute_options[:src].present?
      @tag_options[@attribute_options[:src]] = url
    end

    if @tag_options[:src].present?
      image_tag(@tag_options[:src], @tag_options)
    else
      image_tag(url, @tag_options)
    end
  end
end
