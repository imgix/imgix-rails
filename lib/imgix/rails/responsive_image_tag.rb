require "imgix/rails/tag"

class Imgix::Rails::ResponsiveImageTag < Imgix::Rails::ImageTag
  def render
    @options.merge!({
      srcset: srcset
    })

    super
  end
end