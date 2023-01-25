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

  describe '#ix_image_url' do
    context 'with proper configuration' do
      before do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: "example.imgix.net",
            include_library_param: false
          }
        end
      end

      context 'with a single argument' do
        subject { url_helper.ix_image_url("image(1).png") }

        it 'builds the expected URL' do
          expect(subject).to eq('https://example.imgix.net/image%281%29.png')
        end
      end

      context 'with 2 arguments' do
        context "when the first argument is a string and the second is a hash" do
          subject { url_helper.ix_image_url("image(1).png", params) }
          let(:params) { {key: :value} }

          it { expect(subject).to eq('https://example.imgix.net/image%281%29.png?key=value') }

          context "when disabling path encoding" do
            before { params.merge!(disable_path_encoding: true) }

            it "doesn't encode the URL" do
              expect(subject).to eq( ('https://example.imgix.net/image(1).png?key=value'))
            end
          end
        end

        context "when the first argument is a string and the second too" do
          subject { url_helper.ix_image_url("example.imgix.net", "image(1).png") }

          it { expect(subject).to eq( 'https://example.imgix.net/image%281%29.png') }
        end

        context "when the first argument is not a string" do
          subject { url_helper.ix_image_url(:a, :b) }

          it "raises an error" do
            expect { subject }.to raise_error(RuntimeError)
          end
        end
      end

      context 'with 3 arguments' do
        subject { url_helper.ix_image_url("example.imgix.net", "image(1).png", params) }

        let(:params) { {key: :value} }

        it { expect(subject).to eq( 'https://example.imgix.net/image%281%29.png?key=value') }

        context "when disabling path encoding" do
          before { params.merge!(disable_path_encoding: true) }

          it "doesn't encode the URL" do
            expect(subject).to eq( ('https://example.imgix.net/image(1).png?key=value'))
          end
        end
      end

      context 'with more than 3 arguments' do
        subject { url_helper.ix_image_url(:a, :b, :c, :d) }

        it 'raises an error' do
          expect { subject }.to raise_error(RuntimeError)
        end
      end
    end
  end
end
