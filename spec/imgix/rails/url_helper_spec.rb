require 'imgix/rails/url_helper'

describe Imgix::Rails::UrlHelper do
  let(:truncated_version) { Imgix::Rails::VERSION.split(".").first(2).join(".") }
  let(:url_helper) do
    Class.new do
      include ActionView::Helpers::AssetTagHelper
      include ActionView::Helpers::TextHelper
      include Imgix::Rails::UrlHelper
      include ActionView::Context
    end.new
  end

  before do
    Imgix::Rails.configure { |config| config.imgix = {} }
  end

  describe 'configuration' do
    let(:app) { Class.new(::Rails::Application) }
    let(:source) { "assets.imgix.net" }

    before do
      Imgix::Rails.configure { |config| config.imgix = {} }
    end

    it 'expects config.imgix.source to be defined' do
      expect{
        url_helper.ix_image_url("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError)
    end

    it 'expects config.imgix.source to be a String' do
      Imgix::Rails.configure { |config| config.imgix = { source: 1 } }

      expect{
        url_helper.ix_image_url("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, "imgix source must be a String.")
    end

    it 'optionally expects config.imgix.secure_url_token to be defined' do
      Imgix::Rails.configure do |config|
        config.imgix = {
          source: 'assets.imgix.net',
          secure_url_token: 'FACEBEEF'
        }
      end

      expect{
        url_helper.ix_image_url("assets.png")
      }.not_to raise_error
    end

    it 'sets domain if source is a String' do
      Imgix::Rails.configure do |config|
        config.imgix = {
          source: source
        }
      end

      expect(url_helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
    end

    describe ':use_https' do
      it 'defaults to https' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source
          }
        end

        expect(url_helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end

      it 'respects the :use_https flag' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            use_https: false
          }
        end

        expect(url_helper.ix_image_url("image.jpg")).to eq  "http://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end
    end
  
    describe ':include_library_param' do
      it 'ixlib parameter exists by default' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source
          }
        end

        expect(url_helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end

      it 'respects the :include_library_param flag' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            include_library_param: false
          }
        end

        expect(url_helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg"
      end
    end
  end
end
