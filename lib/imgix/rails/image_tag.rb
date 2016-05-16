require "imgix/rails/tag"

class Imgix::Rails::ImageTag < Imgix::Rails::Tag
  def render
    @options[:srcset] = srcset
    @options[:sizes] ||= '100vw'

    @source = replace_hostname(@source)
    normal_opts = @options.slice!(*self.class.available_parameters)

    image_tag(ix_image_url(@source, @options), normal_opts)
  end
end
