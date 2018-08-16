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
      }.to raise_error(Imgix::Rails::ConfigurationError, "imgix source is not configured. Please set config.imgix[:source].")
    end

    it 'expects config.imgix.source to be a String or an Array' do
      Imgix::Rails.configure { |config| config.imgix = { source: 1 } }

      expect{
        url_helper.ix_image_url("assets.png")
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
        url_helper.ix_image_url("assets.png")
      }.not_to raise_error
    end

    describe 'support host/hosts' do
      it 'sets host if source is a String' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source
          }
        end

        expect(url_helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end

      it 'sets hosts if source is an Array' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: [source]
          }
        end

        expect(url_helper.ix_image_url("image.jpg")).to eq  "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end
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

        expect(url_helper.ix_image_url("https://adifferenthostname.com/image.jpg", w: 400, h: 300)).to eq "https://assets.imgix.net/https%3A%2F%2Fadifferenthostname.com%2Fimage.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300"
      end

      it 'removes a single hostname' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostname_to_replace: hostname
          }
        end

        expect(url_helper.ix_image_url("https://#{hostname}/image.jpg", w: 400, h: 300)).to eq "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300"
      end

      it 'removes multiple configured protocol/hostname combos' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostnames_to_replace: [another_hostname, yet_another_hostname]
          }
        end

        expect(url_helper.ix_image_url("https://#{another_hostname}/image.jpg", w: 400, h: 300)).to eq "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300"
        expect(url_helper.ix_image_url("https://#{yet_another_hostname}/image.jpg", w: 400, h: 300)).to eq "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300"
      end
    end

    describe 'optionally expects shard_strategy' do
      it 'optionally expects crc shard_strategy' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: 'assets.imgix.net',
            shard_strategy: :crc
          }
        end

        expect{
          url_helper.ix_image_url("assets.png")
        }.not_to raise_error
      end

      it 'optionally expects cycle shard_strategy' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: 'assets.imgix.net',
            shard_strategy: :cycle
          }
        end

        expect{
          url_helper.ix_image_url("assets.png")
        }.not_to raise_error
      end
    end

    it 'expects shard_strategy to be :crc or :cycle' do
      Imgix::Rails.configure do |config|
        config.imgix = {
          source: 'assets.imgix.net',
          shard_strategy: :foo
        }
      end

      expect{
        url_helper.ix_image_url("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, "foo is not supported")
    end
  end
end
