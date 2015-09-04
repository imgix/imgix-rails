require 'spec_helper'
require 'rails'
require 'action_view'
require 'imgix/rails/view_helper'
require 'uri'
require 'cgi'

describe Imgix::Rails do
  let(:truncated_version) { Imgix::Rails::VERSION.split(".").first(2).join(".") }
  let(:helper) do
    Class.new do
      include ActionView::Helpers::AssetTagHelper
      include ActionView::Helpers::TextHelper
      include Imgix::Rails::ViewHelper
      include ActionView::Context
    end.new
  end

  before do
    Imgix::Rails.configure { |config| config.imgix = {} }
  end

  it 'has a version number' do
    expect(Imgix::Rails::VERSION).not_to be nil
  end

  it 'pulls in imgix-rb' do
    expect(Imgix::VERSION).not_to be nil
  end

  describe 'configuration' do
    let(:app) { Class.new(::Rails::Application) }
    let(:source) { "assets.imgix.net" }

    before do
      Imgix::Rails.configure { |config| config.imgix = {} }
    end

    it 'expects config.imgix.source to be defined' do
      expect{
        helper.ix_image_tag("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, "imgix source is not configured. Please set config.imgix[:source].")
    end

    it 'expects config.imgix.source to be a String or an Array' do
      Imgix::Rails.configure { |config| config.imgix = { source: 1 } }

      expect{
        helper.ix_image_tag("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, "imgix source must be a String or an Array.")
    end

    it 'optionally expects config.imgix.secure_url_token to be defined' do
      Imgix::Rails.configure do |config|
        config.imgix = {
          source: 'assets.imgix.net',
          secure_url_token: 'FACEBEEF'
        }
      end

      expect{
        helper.ix_image_tag("assets.png")
      }.not_to raise_error
    end

    describe ':secure' do
      it 'defaults to https' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source
          }
        end

        expect(helper.ix_image_tag("image.jpg")).to eq  "<img src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end

      it 'respects the :secure flag' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            secure: false
          }
        end

        expect(helper.ix_image_tag("image.jpg")).to eq  "<img src=\"http://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end
    end

    describe 'hostname removal' do
      let(:hostname) { 's3.amazonaws.com' }
      let(:another_hostname) { 's3-us-west-2.amazonaws.com' }
      let(:yet_another_hostname) { 's3-sa-east-1.amazonaws.com' }
      let(:app) { Class.new(::Rails::Application) }
      let(:source) { "assets.imgix.net" }

      before do
        Imgix::Rails.configure { |config| config.imgix = { source: source } }
      end

      it 'does not remove a hostname for a fully-qualified URL' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostname_to_replace: hostname
          }
        end

        expect(helper.ix_image_tag("https://adifferenthostname.com/image.jpg", w: 400, h: 300)).to eq "<img src=\"https://assets.imgix.net/https%3A%2F%2Fadifferenthostname.com%2Fimage.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&h=300&w=400\" alt=\"Https%3a%2f%2fadifferenthostname.com%2fimage.jpg?ixlib=rails #{truncated_version}\" />"
      end

      it 'removes a single hostname' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostname_to_replace: hostname
          }
        end

        expect(helper.ix_image_tag("https://#{hostname}/image.jpg", w: 400, h: 300)).to eq "<img src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&h=300&w=400\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end

      it 'removes multiple configured protocol/hostname combos' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostnames_to_replace: [another_hostname, yet_another_hostname]
          }
        end

        expect(helper.ix_image_tag("https://#{another_hostname}/image.jpg", w: 400, h: 300)).to eq "<img src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&h=300&w=400\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
        expect(helper.ix_image_tag("https://#{yet_another_hostname}/image.jpg", w: 400, h: 300)).to eq "<img src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&h=300&w=400\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end
    end
  end

  describe Imgix::Rails::ViewHelper do
    let(:app) { Class.new(::Rails::Application) }
    let(:source) { "assets.imgix.net" }

    before do
      Imgix::Rails.configure { |config| config.imgix = { source: source } }
    end

    describe '#ix_image_url' do
      it 'prints an image URL' do
        expect(helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end

      it 'signs image URLs with ixlib=rails' do
        expect(helper.ix_image_url("image.jpg")).to include("ixlib=rails-")
      end

      it 'injects any imgix parameters given' do
        image_url = URI.parse(helper.ix_image_url("image.jpg", { h: 300,  w: 400 }))
        url_query = CGI::parse(image_url.query)

        expect(url_query['w']).to eq ['400']
        expect(url_query['h']).to eq ['300']
      end

      it 'signs an image path if a :secure_url_token is given' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            secure_url_token: "FOO123bar",
            include_library_param: false
          }
        end

        expect(helper.ix_image_url("/users/1.png")).to eq "https://assets.imgix.net/users/1.png?&s=3d97566c016f6e1e6679bf981941e6f4"
      end
    end

    describe '#ix_image_tag' do
      it 'prints an image_tag' do
        expect(helper.ix_image_tag("image.jpg")).to eq  "<img src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end

      it 'passes through non-imgix tags' do
        expect(helper.ix_image_tag("image.jpg", { alt: "No Church in the Wild", w: 400, h: 300 })).to eq "<img alt=\"No Church in the Wild\" src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&h=300&w=400\" />"
      end
    end

    describe '#ix_responsive_image_tag' do
      let(:app) { Class.new(::Rails::Application) }
      let(:source) { "assets.imgix.net" }
      let(:another_hostname) { 's3-us-west-2.amazonaws.com' }

      before do
        Imgix::Rails.configure { |config| config.imgix = { source: source } }
      end

      it 'generates a 1x and 2x image using `srcset` by default' do
        expect(helper.ix_responsive_image_tag("image.jpg")).to eq "<img srcset=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION} 1x, https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&amp;dpr=2 2x\" src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end

      it 'replaces the hostname' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostnames_to_replace: [another_hostname]
          }
        end

        expect(helper.ix_responsive_image_tag("https://#{another_hostname}/image.jpg")).to eq "<img srcset=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION} 1x, https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&amp;dpr=2 2x\" src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" />"
      end
    end

    describe '#ix_picture_tag' do
      it 'generates a picture tag' do
        expect(helper.ix_picture_tag("image.jpg")).to eq "<picture><source srcset=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION} 1x, https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&amp;dpr=2 2x\" /><img src=\"https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}\" alt=\"Image.jpg?ixlib=rails #{truncated_version}\" /></picture>"
      end
    end
  end
end
