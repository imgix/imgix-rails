require "imgix/rails/tag"

class Imgix::Rails::ResponsiveImageTag < Imgix::Rails::ImageTag
  def render
    @options.merge!({
      srcset: srcset_for(@source, @options)
    })

    super
  end
end