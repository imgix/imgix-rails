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

    describe ':use_https' do
      it 'defaults to https' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source
          }
        end

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
        expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}")
      end

      it 'respects the :use_https flag' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            use_https: false
          }
        end

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
        expect(tag.attribute('src').value).to eq("http://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}")
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

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("https://adifferenthostname.com/image.jpg", url_params: {w: 400, h: 300})).children[0]

        expect(tag.attribute('src').value).to eq("https://assets.imgix.net/https%3A%2F%2Fadifferenthostname.com%2Fimage.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300")
      end

      it 'removes a single hostname' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostname_to_replace: hostname
          }
        end

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("https://#{hostname}/image.jpg", url_params: {w: 400, h: 300})).children[0]
        expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300")
      end

      it 'removes multiple configured protocol/hostname combos' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            hostnames_to_replace: [another_hostname, yet_another_hostname]
          }
        end

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("https://#{another_hostname}/image.jpg", url_params: {w: 400, h: 300})).children[0]
        another_tag = Nokogiri::HTML.fragment(helper.ix_image_tag("https://#{yet_another_hostname}/image.jpg", url_params: {w: 400, h: 300})).children[0]

        expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300")
        expect(another_tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&w=400&h=300")
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
        expect(helper.ix_image_url("image.jpg")).to eq "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
      end

      it 'signs image URLs with ixlib=rails' do
        image_url = URI.parse(helper.ix_image_url("image.jpg", { h: 300,  w: 400 }))
        url_query = CGI::parse(image_url.query)
        expect(url_query['ixlib']).to eq ["rails-#{Imgix::Rails::VERSION}"]
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

        expect(helper.ix_image_url("/users/1.png")).to eq "https://assets.imgix.net/users/1.png?s=6797c24146142d5b40bde3141fd3600c"
      end
    end

    describe '#ix_image_tag' do
      describe '#ix_picture_tag directly specifying options' do
        it 'prints an image_tag' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
            expect(tag.name).to eq('img')
          end
        end

        it 'passes through non-imgix tags' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", alt: "No Church in the Wild", w: 400, h: 300)).children[0]
            expect(tag.attribute('alt').value).to eq('No Church in the Wild')
          end
        end

        it 'adds exact 1x, 2x, and 3x multiples of the passed `w` to the generated `srcset`' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', w: 430)).children[0]
            expect(tag.attribute('srcset').value).to include('430w')
            expect(tag.attribute('srcset').value).to include('860w')
            expect(tag.attribute('srcset').value).to include('1290w')
          end
        end

        it 'allows explicitly specifying desired widths' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], w: 400, h: 300)).children[0]
            expect(tag.attribute('srcset').value).to include('10w')
            expect(tag.attribute('srcset').value).to include('20w')
            expect(tag.attribute('srcset').value).to include('30w')
          end
        end

        it 'does not include `widths` as an attribute in the generated tag' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], w: 400, h: 300)).children[0]
            expect(tag.attribute('widths')).to be_nil
          end
        end

        it 'does not include `widths` as a query parameter in the generated `srcset`' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], w: 400, h: 300)).children[0]
            expect(tag.attribute('srcset').value).not_to include('widths')
          end
        end

        it 'does not include `widths` as a query parameter in the generated `src`' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], w: 400, h: 300)).children[0]
            expect(tag.attribute('src').value).not_to include('widths')
          end
        end

        it 'applies the client-hints parameter' do
          ActiveSupport::Deprecation.silence do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", ch: "Width,DPR")).children[0]
            expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&ch=Width%2CDPR")
          end
        end

        describe 'sizes' do
          it 'sets a default value of 100vw if not specified' do
            ActiveSupport::Deprecation.silence do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg')).children[0]
              expect(tag.attribute('sizes').value).to eq('100vw')
            end
          end

          it 'does not override an explicit `sizes` value' do
            ActiveSupport::Deprecation.silence do
              sizes_value = 'calc(100vw - 20px - 50%)'
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', sizes: sizes_value)).children[0]
              expect(tag.attribute('sizes').value).to eq(sizes_value)
            end
          end
        end

        describe 'srcset' do
          let(:app) { Class.new(::Rails::Application) }
          let(:source) { "assets.imgix.net" }
          let(:another_hostname) { 's3-us-west-2.amazonaws.com' }

          before do
            Imgix::Rails.configure { |config| config.imgix = { source: source } }
          end

          it 'generates the expected number of srcset values' do
            ActiveSupport::Deprecation.silence do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
              expect(tag.attribute('srcset').value.split(',').size).to eq(71)
            end
          end

          it 'correctly calculates `h` to maintain aspect ratio, when specified' do
            ActiveSupport::Deprecation.silence do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('presskit/imgix-presskit.pdf', page: 3, w: 600, h: 300)).children[0]
              tag.attribute('srcset').value.split(',').each do |srcsetPair|
                w = srcsetPair.match(/w=(\d+)/)[1].to_i
                h = srcsetPair.match(/h=(\d+)/)[1].to_i
                expect((w / 2.0).round).to eq(h)
              end
            end
          end

          context 'with min_width' do
            let(:tag) do
              ActiveSupport::Deprecation.silence do
                Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", min_width: 2560)).children[0]
              end
            end

            it 'generates the expected number of srcset values' do
              expect(tag.attribute('srcset').value.split(',').size).to eq(29)
            end
          end

          context 'with max_width' do
            let(:tag) do
              ActiveSupport::Deprecation.silence do
                Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", max_width: 100)).children[0]
              end
            end

            it 'generates the expected number of srcset values' do
              expect(tag.attribute('srcset').value.split(',').size).to eq(1)
            end
          end

          it 'replaces the hostname' do
            Imgix::Rails.configure do |config|
              config.imgix = {
                source: source,
                hostnames_to_replace: [another_hostname]
              }
            end

            ActiveSupport::Deprecation.silence do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag("https://#{another_hostname}/image.jpg")).children[0]
              expect(tag.attribute('srcset').value).not_to include(another_hostname)
            end
          end
        end
      end

      describe '#ix_picture_tag using :tag_options and :url_params' do
        it 'prints an image_tag' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
          expect(tag.name).to eq('img')
        end

        it 'passes through non-imgix tags' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", tag_options: {alt: "No Church in the Wild"}, url_params: {w: 400, h: 300})).children[0]
          expect(tag.attribute('alt').value).to eq('No Church in the Wild')
        end

        it 'passes through non-imgix url params' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", tag_options: {alt: "No Church in the Wild"}, url_params: {w: 400, h: 300, foo: "bar"})).children[0]
          expect(tag.attribute('src').value).to include('foo=bar')
        end

        it 'adds exact 1x, 2x, and 3x multiples of the passed `w` to the generated `srcset`' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', url_params: {w: 430})).children[0]
          expect(tag.attribute('srcset').value).to include('430w')
          expect(tag.attribute('srcset').value).to include('860w')
          expect(tag.attribute('srcset').value).to include('1290w')
        end

        it 'allows explicitly specifying desired widths' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], url_params: {w: 400, h: 300})).children[0]
          expect(tag.attribute('srcset').value).to include('10w')
          expect(tag.attribute('srcset').value).to include('20w')
          expect(tag.attribute('srcset').value).to include('30w')
        end

        it 'does not include `widths` as an attribute in the generated tag' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], url_params: {w: 400, h: 300})).children[0]
          expect(tag.attribute('widths')).to be_nil
        end

        it 'does not include `widths` as a query parameter in the generated `srcset`' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], url_params: {w: 400, h: 300})).children[0]
          expect(tag.attribute('srcset').value).not_to include('widths')
        end

        it 'does not include `widths` as a query parameter in the generated `src`' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', widths: [10, 20, 30], url_params: {w: 400, h: 300})).children[0]
          expect(tag.attribute('src').value).not_to include('widths')
        end

        it 'applies the client-hints parameter' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", url_params: {ch: "Width,DPR"})).children[0]
          expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}&ch=Width%2CDPR")
        end

        describe 'sizes' do
          it 'sets a default value of 100vw if not specified' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg')).children[0]
            expect(tag.attribute('sizes').value).to eq('100vw')
          end

          it 'does not override an explicit `sizes` value' do
            sizes_value = 'calc(100vw - 20px - 50%)'
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', tag_options: {sizes: sizes_value})).children[0]
            expect(tag.attribute('sizes').value).to eq(sizes_value)
          end
        end

        describe 'srcset' do
          let(:app) { Class.new(::Rails::Application) }
          let(:source) { "assets.imgix.net" }
          let(:another_hostname) { 's3-us-west-2.amazonaws.com' }

          before do
            Imgix::Rails.configure { |config| config.imgix = { source: source } }
          end

          it 'generates the expected number of srcset values' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
            expect(tag.attribute('srcset').value.split(',').size).to eq(71)
          end

          it 'correctly calculates `h` to maintain aspect ratio, when specified' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag('presskit/imgix-presskit.pdf', url_params: {page: 3, w: 600, h: 300})).children[0]
            tag.attribute('srcset').value.split(',').each do |srcsetPair|
              w = srcsetPair.match(/w=(\d+)/)[1].to_i
              h = srcsetPair.match(/h=(\d+)/)[1].to_i
              expect((w / 2.0).round).to eq(h)
            end
          end

          context 'with min_width' do
            let(:tag) do
              Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", tag_options: {min_width: 2560})).children[0]
            end

            it 'generates the expected number of srcset values' do
              expect(tag.attribute('srcset').value.split(',').size).to eq(29)
            end
          end

          context 'with max_width' do
            let(:tag) do
              Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", tag_options: {max_width: 100})).children[0]
            end

            it 'generates the expected number of srcset values' do
              expect(tag.attribute('srcset').value.split(',').size).to eq(1)
            end
          end

          it 'replaces the hostname' do
            Imgix::Rails.configure do |config|
              config.imgix = {
                source: source,
                hostnames_to_replace: [another_hostname]
              }
            end

            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("https://#{another_hostname}/image.jpg")).children[0]
            expect(tag.attribute('srcset').value).not_to include(another_hostname)
          end
        end
      end
    end

    describe '#ix_picture_tag' do
      describe '#ix_picture_tag using :picture_tag_options and :imgix_default_options' do
        let(:tag) do
          ActiveSupport::Deprecation.silence do
            picture_tag = helper.ix_picture_tag(
              'bertandernie.jpg',
              picture_tag_options: {
                class: 'a-picture-tag'
              },
              imgix_default_options: {
                w: 300,
                h: 300,
                fit: 'crop',
              },
              breakpoints: {
                '(max-width: 640px)' => {
                  h: 100,
                  sizes: 'calc(100vw - 20px)'
                },
                '(max-width: 880px)' => {
                  crop: 'right',
                  sizes: 'calc(100vw - 20px - 50%)'
                },
                '(min-width: 881px)' => {
                  crop: 'left',
                  sizes: '430px'
                }
              }
            )

            Nokogiri::HTML.fragment(picture_tag).children[0]
          end
        end

        it 'generates a `picture`' do
          expect(tag.name).to eq('picture')
        end

        it 'passes through options to the `picture`' do
          expect(tag.attribute('class').value).to eq('a-picture-tag')
        end

        it 'generates the specified number of `source` children' do
          expect(tag.css('source').length).to eq(3)
        end

        it 'generates a fallback `img` child' do
          expect(tag.css('img').length).to eq(1)
        end

        it 'sets the specified `media` on each `source`' do
          expected_media = [
            '(max-width: 640px)',
            '(max-width: 880px)',
            '(min-width: 881px)'
          ]

          tag.css('source').each_with_index do |source, i|
            expect(source.attribute('media').value).to eq(expected_media[i])
          end
        end

        it 'sets the specified `sizes` on each `source`' do
          expected_sizes = [
            'calc(100vw - 20px)',
            'calc(100vw - 20px - 50%)',
            '430px'
          ]

          tag.css('source').each_with_index do |source, i|
            expect(source.attribute('sizes').value).to eq(expected_sizes[i])
          end
        end
      end

      describe '#ix_picture_tag using :tag_options and :url_params' do
        let(:tag) do
          picture_tag = helper.ix_picture_tag(
            'bertandernie.jpg',
            tag_options: {
              class: 'a-picture-tag'
            },
            url_params: {
              w: 300,
              h: 300,
              fit: 'crop',
            },
            breakpoints: {
              '(max-width: 640px)' => {
                tag_options: {
                  sizes: 'calc(100vw - 20px)'
                },
                url_params: {
                  h: 100,
                }
              },
              '(max-width: 880px)' => {
                url_params: {
                  crop: 'right'
                },
                tag_options: {
                  sizes: 'calc(100vw - 20px - 50%)'
                }
              },
              '(min-width: 881px)' => {
                url_params: {
                  crop: 'left',
                },
                tag_options: {
                  sizes: '430px'
                }
              }
            }
          )

          Nokogiri::HTML.fragment(picture_tag).children[0]
        end

        it 'generates a `picture`' do
          expect(tag.name).to eq('picture')
        end

        it 'passes through options to the `picture`' do
          expect(tag.attribute('class').value).to eq('a-picture-tag')
        end

        it 'generates the specified number of `source` children' do
          expect(tag.css('source').length).to eq(3)
        end

        it 'generates a fallback `img` child' do
          expect(tag.css('img').length).to eq(1)
        end

        it 'sets the specified `media` on each `source`' do
          expected_media = [
            '(max-width: 640px)',
            '(max-width: 880px)',
            '(min-width: 881px)'
          ]

          tag.css('source').each_with_index do |source, i|
            expect(source.attribute('media').value).to eq(expected_media[i])
          end
        end

        it 'sets the specified `sizes` on each `source`' do
          expected_sizes = [
            'calc(100vw - 20px)',
            'calc(100vw - 20px - 50%)',
            '430px'
          ]

          tag.css('source').each_with_index do |source, i|
            expect(source.attribute('sizes').value).to eq(expected_sizes[i])
          end
        end
      end
    end
  end
end
