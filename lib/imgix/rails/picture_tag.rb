require "imgix/rails/tag"
require "imgix/rails/image_tag"

class Imgix::Rails::PictureTag < Imgix::Rails::Tag
  include ActionView::Context

  def render
    content_tag(:picture) do
      concat(tag(:source, srcset: srcset))
      concat(Imgix::Rails::ImageTag.new(@source, @options).render)
    end
  end
end