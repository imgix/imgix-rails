require "imgix/rails/url_helper"

class Imgix::Rails::Tag
  include Imgix::Rails::UrlHelper
  include ActionView::Helpers

  def initialize(source, tag_options: {}, url_params: {}, widths: [])
    @source = source
    @tag_options = tag_options
    @url_params = url_params
    @widths = widths.length > 0 ? widths : target_widths
  end

protected

  def srcset(url_params: @url_params, widths: @widths)
    @source = replace_hostname(@source)
    widths = widths || target_widths

    widths.map do |width|
      srcset_url_params = url_params.clone
      srcset_url_params[:w] = width

      if url_params[:w].present? && url_params[:h].present?
        srcset_url_params[:h] = (width * (url_params[:h].to_f / url_params[:w])).round
      end

      "#{ix_image_url(@source, srcset_url_params)} #{width}w"
    end.join(', ')
  end

private

  MAXIMUM_SCREEN_WIDTH = 2560 * 2 # Physical resolution of 27" iMac (2016)
  SCREEN_STEP = 100

  # Taken from http://mydevice.io/devices/

  # Phones
  IPHONE = { css_width: 320, dpr: 1 }
  IPHONE_4 = { css_width: 320, dpr: 2 }
  IPHONE_6 = { css_width: 375, dpr: 2 }
  LG_G3 = { css_width: 360, dpr: 4 }

  # Phablets
  IPHONE_6_PLUS = { css_width: 414, dpr: 3 }
  IPHONE_6_PLUS_LANDSCAPE = { css_width: 736, dpr: 3 }
  MOTO_NEXUS_6 = { css_width: 412, dpr: 3.5 }
  MOTO_NEXUS_6_LANDSCAPE = { css_width: 690, dpr: 3.5 }
  LUMIA_1520 = { css_width: 432, dpr: 2.5 }
  LUMIA_1520_LANDSCAPE = { css_width: 768, dpr: 2.5 }
  GALAXY_NOTE_3 = { css_width: 360, dpr: 3 }
  GALAXY_NOTE_3_LANDSCAPE = { css_width: 640, dpr: 3 }
  GALAXY_NOTE_4 = { css_width: 360, dpr: 4 }
  GALAXY_NOTE_4_LANDSCAPE = { css_width: 640, dpr: 4 }

  # Tablets
  IPAD = { css_width: 768, dpr: 1 };
  IPAD_LANDSCAPE = { css_width: 1024, dpr: 1 };
  IPAD_3 = { css_width: 768, dpr: 2 };
  IPAD_3_LANDSCAPE = { css_width: 1024, dpr: 2 };
  IPAD_PRO = { css_width: 1024, dpr: 2 };
  IPAD_PRO_LANDSCAPE = { css_width: 1366, dpr: 2 };

  BOOTSTRAP_SM = { css_width: 576, dpr: 1 }
  BOOTSTRAP_MD = { css_width: 720, dpr: 1 }
  BOOTSTRAP_LG = { css_width: 940, dpr: 1 }
  BOOTSTRAP_XL = { css_width: 1140, dpr: 1 }

  def devices
    phones + phablets + tablets + bootstrap_breaks
  end

  def bootstrap_breaks
    breaks = [
      BOOTSTRAP_SM,
      BOOTSTRAP_MD,
      BOOTSTRAP_LG,
      BOOTSTRAP_XL
    ]

    breaks + breaks.map { |b| b[:dpr] = 2; b }
  end

  def phones
    [
      IPHONE,
      IPHONE_4,
      IPHONE_6,
      LG_G3
    ]
  end

  def phablets
    [
      IPHONE_6_PLUS,
      IPHONE_6_PLUS_LANDSCAPE,
      MOTO_NEXUS_6,
      MOTO_NEXUS_6_LANDSCAPE,
      LUMIA_1520,
      LUMIA_1520_LANDSCAPE,
      GALAXY_NOTE_3,
      GALAXY_NOTE_3_LANDSCAPE,
      GALAXY_NOTE_4,
      GALAXY_NOTE_4_LANDSCAPE
    ]
  end

  def tablets
    [
      IPAD,
      IPAD_LANDSCAPE,
      IPAD_3,
      IPAD_3_LANDSCAPE,
      IPAD_PRO,
      IPAD_PRO_LANDSCAPE
    ]
  end

  # Return the widths to generate given the input `sizes`
  # attribute.
  #
  # @return {Array} An array of {Fixnum} instances representing the unique `srcset` URLs to generate.
  def target_widths
    min_screen_width_required = @tag_options[:min_width] || SCREEN_STEP
    max_screen_width_required = @tag_options[:max_width] || MAXIMUM_SCREEN_WIDTH

    widths = (device_widths + screen_widths).select do |w|
      w <= max_screen_width_required && w >= min_screen_width_required
    end.compact.uniq.sort

    # Add exact widths for 1x, 2x, and 3x devices
    if @url_params[:w]
      widths.push(@url_params[:w], @url_params[:w] * 2, @url_params[:w] * 3)
    end

    widths
  end

  def device_widths
    devices.map do |device|
      (device[:css_width] * device[:dpr]).round
    end
  end

  # Generates an array of physical screen widths to represent
  # the different potential viewport sizes.
  #
  # We step by `SCREEN_STEP` to give some sanity to the amount
  # of widths we output.
  #
  # The upper bound is the widest known screen on the planet.
  # @return {Array} An array of {Fixnum} instances
  def screen_widths
    (0..MAXIMUM_SCREEN_WIDTH).step(SCREEN_STEP).to_a + [MAXIMUM_SCREEN_WIDTH]
  end
end
