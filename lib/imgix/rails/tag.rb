require "imgix/rails/url_helper"

class Imgix::Rails::Tag
  include Imgix::Rails::UrlHelper
  include ActionView::Helpers

  @@parameters = nil

  # Store our parameter information on the class instance so that
  # each instance of any this class or our subclasses doesn't have to
  # go back to disk to get this configuration information
  def self.available_parameters
    @@available_parameters ||= parameters.keys
  end

  def self.parameters
    return @@parameters if @@parameters

    path = File.expand_path("../../../../vendor/parameters.json", __FILE__)
    @@parameters ||= JSON.parse(File.read(path), symbolize_names: true)[:parameters]
  end

  def initialize(source, options={})
    @source = source
    @options = options
  end

protected

  def srcset
    @source = replace_hostname(@source)
    target_widths.map do |w|
      srcset_options = @options.slice(*self.class.available_parameters)
      srcset_options[:w] = w
      "#{ix_image_url(@source, srcset_options)} #{w}w"
    end.join(', ')
  end

private

  MAX_SCREEN_WIDTH_ON_THE_PLANET = 2560 * 2 # Physical resolution of 27" iMac (2016)
  SCREEN_STEP = 50

  # Taken from http://mydevice.io/devices/

  # Phones
  IPHONE_3 = { css_width: 320, dpr: 1 }
  IPHONE_4 = { css_width: 320, dpr: 2 }
  IPHONE_5 = { css_width: 320, dpr: 2 }
  IPHONE_6 = { css_width: 375, dpr: 2 }
  IPHONE_6_PLUS = { css_width: 414, dpr: 3 }
  LG_G4 = { css_width: 360, dpr: 4 }
  LG_G3 = { css_width: 360, dpr: 4 }

  # Phablets
  MOTO_NEXUS_6 = { css_width: 412, dpr: 3.5 }
  MICROSOFT_LUMIA_1520 = { css_width: 432, dpr: 2.5 }
  SAMSUNG_GALAXY_NOTE_4 = { css_width: 360, dpr: 4 }
  SAMSUNG_GALAXY_NOTE_3 = { css_width: 360, dpr: 3 }

  # Tablets
  IPAD_AIR = { css_width: 768, dpr: 2 }
  IPAD_OLD = { css_width: 768, dpr: 1 }
  IPAD_PRO = { css_width: 1024, dpr: 2 }

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

    breaks + breaks.map{ |b| b[:dpr] = 2; b }
  end

  def phones
    [
      IPHONE_3,
      IPHONE_4,
      IPHONE_5,
      IPHONE_6,
      LG_G4,
      LG_G3
    ]
  end

  def phablets
    [
      IPHONE_6_PLUS,
      MOTO_NEXUS_6,
      MICROSOFT_LUMIA_1520,
      SAMSUNG_GALAXY_NOTE_4,
      SAMSUNG_GALAXY_NOTE_3,
    ]
  end

  def tablets
    [
      IPAD_AIR,
      IPAD_OLD,
      IPAD_PRO
    ]
  end

  # Return the widths to generate given the input `sizes`
  # attribute.
  #
  # @return {Array} An array of {Fixnum} instances representing the unique `srcset` URLs to generate.
  def target_widths
    (device_widths + screen_widths).select do |w|
      w <= max_screen_width_required && w >= min_screen_width_required
    end.compact.uniq.sort
  end

  def device_widths
    devices.map do |device|
      device[:css_width] * device[:dpr]
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
    (0..MAX_SCREEN_WIDTH_ON_THE_PLANET).step(SCREEN_STEP).to_a + [MAX_SCREEN_WIDTH_ON_THE_PLANET]
  end

  # Looks for a given `:sizes` passed into the tag and attempts to
  # parse media queries to see which sizes are actually needed.
  # We do this in an attempt to cut down on the total number of
  # widths defined, thereby reducing the total output size of the
  # HTML.
  #
  # If we are unable set bounds on our pixel widths, we include all
  # widths
  def max_screen_width_required
    pixel_match = /\(min-width: \d+px\) (\d+)(px|w)/.match(@options[:sizes])

    if @options[:sizes] == "100vw" || @options[:sizes].blank?
      MAX_SCREEN_WIDTH_ON_THE_PLANET
    elsif pixel_match
      pixel_match[1].to_i
    else
      MAX_SCREEN_WIDTH_ON_THE_PLANET
    end
  end

  def min_screen_width_required
    pixel_match = /\(max-width: \d+px\) (\d+)(px|w)/.match(@options[:sizes])

    if pixel_match
      pixel_match[1].to_i
    else
      0
    end
  end
end