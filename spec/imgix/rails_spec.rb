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
      }.to raise_error(Imgix::Rails::ConfigurationError)
    end

    it 'expects config.imgix.source to be a String' do
      Imgix::Rails.configure { |config| config.imgix = { source: 1 } }

      expect{
        helper.ix_image_tag("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, "imgix source must be a String.")
    end

    it 'expects either a :source or :sources, but not both' do
      Imgix::Rails.configure { |config| config.imgix = { source: "domain1", sources: "domain2" } }
      
      expect{
        helper.ix_image_url("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, "Exactly one of :source, :sources is required")
    end

    it 'expects :sources to be a hash' do
      Imgix::Rails.configure { |config| 
        config.imgix = {
          sources: 1
        }
      }

      expect{
        helper.ix_image_url("assets.png")
      }.to raise_error(Imgix::Rails::ConfigurationError, ":sources must be a Hash")
    end

    it 'validates an imgix domain' do
      Imgix::Rails.configure { |config| config.imgix = { source: "domain1" } }

      expect{
        helper.ix_image_url("assets.png")
      }.to raise_error(ArgumentError)
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

    describe ':include_library_param' do
      it 'ixlib parameter exists by default' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source
          }
        end

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
        expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}")
      end

      it 'respects the :include_library_param flag' do
        Imgix::Rails.configure do |config|
          config.imgix = {
            source: source,
            include_library_param: false
          }
        end

        tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
        expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg")
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

      it 'raises error when path not supplied' do
        expect{
          helper.ix_image_url()
        }.to raise_error(RuntimeError)
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
          expect(tag.attribute('srcset').value.split(',').size).to eq(31)
        end

        it 'generates the excpected number of srcset values with custom srcset-width-tolerance' do
          Imgix::Rails.configure do |config|
            config.imgix = {
              source: "asserts.imgix.net",
              srcset_width_tolerance: 0.5,
            }
          end

          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]

          expect(tag.attribute('srcset').value.split(',').size).to eq(8)
        end

        context 'with fixed-image rendering' do
          it 'generates a DPR srcset' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", url_params: {w: 1000})).children[0]
            expect(tag.attribute('srcset').value).to include('1x')
            expect(tag.attribute('srcset').value).to include('2x')
            expect(tag.attribute('srcset').value).to include('3x')
            expect(tag.attribute('srcset').value).to include('4x')
            expect(tag.attribute('srcset').value).to include('5x')
          end

          it 'includes variable qualities per each entry' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", url_params: {w: 1000})).children[0]
            expect(tag.attribute('srcset').value).to include('q=75')
            expect(tag.attribute('srcset').value).to include('q=50')
            expect(tag.attribute('srcset').value).to include('q=35')
            expect(tag.attribute('srcset').value).to include('q=23')
            expect(tag.attribute('srcset').value).to include('q=20')
          end
        end

        context 'with srcset_options' do
          it 'allows variable qualities to be disabled' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", url_params: {w: 1000}, srcset_options:{disable_variable_quality: true})).children[0]
            expect(tag.attribute('srcset').value).not_to include('q=75')
            expect(tag.attribute('srcset').value).not_to include('q=50')
            expect(tag.attribute('srcset').value).not_to include('q=35')
            expect(tag.attribute('srcset').value).not_to include('q=23')
            expect(tag.attribute('srcset').value).not_to include('q=20')
          end

          context 'min_width' do
            let(:tag) do
              Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", srcset_options: {min_width: 2560})).children[0]
            end

            it 'generates the expected number of srcset values' do
              expect(tag.attribute('srcset').value.split(',').size).to eq(9)
            end

            it 'does not include min_width as an attribute' do
              expect(tag.attribute('min_width')).to be_nil
            end
          end

          context 'max_width' do
            let(:tag) do
              Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", srcset_options: {max_width: 100})).children[0]
            end

            it 'generates the expected number of srcset values' do
              expect(tag.attribute('srcset').value.split(',').size).to eq(1)
            end

            it 'does not include max_width as an attribute' do
              expect(tag.attribute('max_width')).to be_nil
            end
          end

          context 'widths' do
            it 'allows explicitly specifying desired widths' do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', srcset_options: {widths: [100, 500, 800, 1200]})).children[0]
              expect(tag.attribute('srcset').value).to include('100w')
              expect(tag.attribute('srcset').value).to include('500w')
              expect(tag.attribute('srcset').value).to include('800w')
              expect(tag.attribute('srcset').value).to include('1200w')
            end

            it 'does not include `widths` as an attribute in the generated tag' do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', srcset_options: {widths: [10, 20, 30]}, url_params: {w: 400, h: 300})).children[0]
              expect(tag.attribute('widths')).to be_nil
            end

            it 'does not include `widths` as a query parameter in the generated `srcset`' do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', srcset_options: {widths: [10, 20, 30]}, url_params: {w: 400, h: 300})).children[0]
              expect(tag.attribute('srcset').value).not_to include('widths')
            end

            it 'does not include `widths` as a query parameter in the generated `src`' do
              tag = Nokogiri::HTML.fragment(helper.ix_image_tag('image.jpg', srcset_options: {widths: [10, 20, 30]}, url_params: {w: 400, h: 300})).children[0]
              expect(tag.attribute('src').value).not_to include('widths')
            end
          end
        end
      end
      describe 'lazy' do
        it 'sets the original path to data-src' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", attribute_options: { src: "data-src", srcset: "data-srcset", sizes: "data-sizes"}, tag_options: {src: "lazy.jpg"})).children[0]
          expect(tag.attribute('data-src').value).to eq "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
        end

        it 'sets src to image provided with lazy' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", attribute_options: { src: "data-src", srcset: "data-srcset", sizes: "data-sizes"}, tag_options: {src: "lazy.jpg"})).children[0]
          expect(tag.attribute('src').value).to eq "/images/lazy.jpg"
        end

        it 'keeps the sourcesets on data-sourcesets' do
          tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", attribute_options: { src: "data-src", srcset: "data-srcset", sizes: "data-sizes"}, tag_options: {src: "lazy.jpg"})).children[0]
          expect(tag.attribute('data-srcset').value.split(',').size).to eq(31)
        end
      end
    end

    describe '#ix_picture_tag' do
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

      it 'throws error on unsupported options in breakpoints' do
        expect{
          helper.ix_picture_tag(
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
                foo: 'foo',
                bar: 'bar',
                tag_options: {
                  sizes: 'calc(100vw - 20px)'
                },
                url_params: {
                  h: 100,
                }
              }
            }
          )
        }.to raise_error(RuntimeError, /key\(s\) not supported/)
      end

      context 'with srcset_options' do

        it 'allows variable qualities to be disabled' do
          picture_tag = helper.ix_picture_tag(
            'bertandernie.jpg',
            tag_options: {
            },
            url_params: {
              w:1000
            },
            srcset_options: {
              disable_variable_quality: true
            },
            breakpoints: {
              '(max-width: 640px)' => {
                tag_options: {
                  sizes: 'calc(100vw - 20px)'
                },
                url_params: {
                  h: 100,
                }
              }
            }
          )
          tag = Nokogiri::HTML.fragment(picture_tag).children[0]

          expect(tag.children[1].attribute('srcset').value).not_to include('q=75')
          expect(tag.children[1].attribute('srcset').value).not_to include('q=50')
          expect(tag.children[1].attribute('srcset').value).not_to include('q=35')
          expect(tag.children[1].attribute('srcset').value).not_to include('q=23')
          expect(tag.children[1].attribute('srcset').value).not_to include('q=20')
        end

        context 'min_width' do
          let(:tag) do
            picture_tag = helper.ix_picture_tag(
              'bertandernie.jpg',
              tag_options: {
              },
              url_params: {
              },
              srcset_options: {
                min_width: 6000
              },
              breakpoints: {
                '(max-width: 640px)' => {
                  tag_options: {
                    sizes: 'calc(100vw - 20px)'
                  },
                  url_params: {
                    h: 100,
                  }
                }
              }
            )
    
            Nokogiri::HTML.fragment(picture_tag).children[0]
          end

          it 'generates the expected number of srcset values' do
            expect(tag.children[1].attribute('srcset').value.split(',').size).to eq(4)
          end

          it 'does not include min_width as an attribute' do
            expect(tag.children[1].attribute('min_width')).to be_nil
          end
        end

        context 'max_width' do
          let(:tag) do
            picture_tag = helper.ix_picture_tag(
              'bertandernie.jpg',
              tag_options: {
              },
              url_params: {
              },
              srcset_options: {
                max_width: 1000
              },
              breakpoints: {
                '(max-width: 640px)' => {
                  tag_options: {
                    sizes: 'calc(100vw - 20px)'
                  },
                  url_params: {
                    h: 100,
                  }
                }
              }
            )
    
            Nokogiri::HTML.fragment(picture_tag).children[0]
          end

          it 'generates the expected number of srcset values' do
            expect(tag.children[1].attribute('srcset').value.split(',').size).to eq(17)
          end

          it 'does not include max_width as an attribute' do
            expect(tag.children[1].attribute('max_width')).to be_nil
          end
        end

        context 'widths' do
          let(:tag) do
            picture_tag = helper.ix_picture_tag(
              'bertandernie.jpg',
              tag_options: {
              },
              url_params: {
              },
              srcset_options: {
                widths:[100,500,800,1200]
              },
              breakpoints: {
                '(max-width: 640px)' => {
                  tag_options: {
                    sizes: 'calc(100vw - 20px)'
                  },
                  url_params: {
                    h: 100,
                  }
                }
              }
            )
    
            Nokogiri::HTML.fragment(picture_tag).children[0]
          end

          it 'allows explicitly specifying desired widths' do
            expect(tag.children[1].attribute('srcset').value).to include('100w')
            expect(tag.children[1].attribute('srcset').value).to include('500w')
            expect(tag.children[1].attribute('srcset').value).to include('800w')
            expect(tag.children[1].attribute('srcset').value).to include('1200w')
          end

          it 'does not include `widths` as an attribute in the generated tag' do
            expect(tag.children[1].attribute('widths')).to be_nil
          end

          it 'does not include `widths` as a query parameter in the generated `srcset`' do
            expect(tag.children[1].attribute('srcset').value).not_to include('widths')
          end

          it 'does not include `widths` as a query parameter in the generated `src`' do
            expect(tag.children[1].attribute('src').value).not_to include('widths')
          end
        end
      end
    end
  end

  describe 'multi-source' do
    describe 'with default_source specified' do
      let(:app) { Class.new(::Rails::Application) }
      let(:sources) { { "assets.imgix.net" => nil, "assets2.imgix.net" => nil } }
      let(:default_source) { "assets.imgix.net" }

      before do
        Imgix::Rails.configure { |config| config.imgix = { sources: sources, default_source: default_source } }
      end

      describe '#ix_image_url' do
        describe 'prints an image URL' do
            it 'with no source supplied' do
              expect(helper.ix_image_url("image.jpg")).to eq "https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
            end

            it 'with explicit source supplied' do
              expect(helper.ix_image_url("assets2.imgix.net", "image.jpg")).to eq "https://assets2.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}"
            end
        end

        describe 'injects any imgix parameters given' do
          it 'with no source supplied' do
            image_url = URI.parse(helper.ix_image_url("image.jpg", { h: 300,  w: 400 }))
            url_query = CGI::parse(image_url.query)

            expect(url_query['w']).to eq ['400']
            expect(url_query['h']).to eq ['300']
          end

          it 'with explicit source supplied' do
            image_url = URI.parse(helper.ix_image_url("assets2.imgix.net", "image.jpg", { h: 300,  w: 400 }))
            url_query = CGI::parse(image_url.query)

            expect(url_query['w']).to eq ['400']
            expect(url_query['h']).to eq ['300']
          end
        end

        describe 'signs an image path if a :secure_url_token is given' do
          before do
            Imgix::Rails.configure do |config|
              config.imgix = {
                sources: {
                  "assets.imgix.net" => "FOO123bar",
                  "assets2.imgix.net" => "bazbarfoo",
                },
                default_source: "assets.imgix.net",
                include_library_param: false
              }
            end
          end

          it 'with no source supplied' do
            expect(helper.ix_image_url("/users/1.png")).to eq "https://assets.imgix.net/users/1.png?s=6797c24146142d5b40bde3141fd3600c"
          end

          it 'with default source explicitly supplied' do
            expect(helper.ix_image_url("assets.imgix.net", "/users/1.png")).to eq "https://assets.imgix.net/users/1.png?s=6797c24146142d5b40bde3141fd3600c"
          end

          it 'with different source explicity supplied' do
            expect(helper.ix_image_url("assets2.imgix.net", "/users/1.png")).to eq "https://assets2.imgix.net/users/1.png?s=07b9d5cf18f35c04f1e1872d9ccfa6ea"
          end
        end
      end

      describe '#ix_image_tag' do
        describe 'prints an image_tag' do
          it 'with no source supplied' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg")).children[0]
            expect(tag.name).to eq('img')
            expect(tag.attribute('src').value).to eq("https://assets.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}")
          end

          it 'with explicit source supplied' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("assets2.imgix.net", "image.jpg")).children[0]
            expect(tag.name).to eq('img')
            expect(tag.attribute('src').value).to eq("https://assets2.imgix.net/image.jpg?ixlib=rails-#{Imgix::Rails::VERSION}")
          end
        end

        describe 'passes through tag_options, url_params' do
          it 'with no source supplied' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("image.jpg", tag_options: {alt: "No Church in the Wild"}, url_params: {w: 400, h: 300, foo: "bar"})).children[0]
            expect(tag.attribute('src').value).to include('foo=bar')
          end

          it 'with explicit source supplied' do
            tag = Nokogiri::HTML.fragment(helper.ix_image_tag("assets2.imgix.net", "image.jpg", tag_options: {alt: "No Church in the Wild"}, url_params: {w: 400, h: 300, foo: "bar"})).children[0]
            expect(tag.attribute('src').value).to include('w=400')
            expect(tag.attribute('src').value).to include('h=300')
            expect(tag.attribute('src').value).to include('foo=bar')
            expect(tag.attribute('alt').value).to eq("No Church in the Wild")
          end
        end
      end

      describe '#ix_picture_tag' do
        let(:tag_options) { { class: 'a-picture-tag' } }
        let(:url_params) { {
              w: 300,
              h: 300,
              fit: 'crop',
            } }
        let(:breakpoints) { {
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
            } }

        describe 'generates a `picture`' do
          it 'with no source supplied' do
            picture_tag = helper.ix_picture_tag(
              'bertandernie.jpg',
              tag_options: tag_options,
              url_params: url_params,
              breakpoints: breakpoints,
            )
            tag = Nokogiri::HTML.fragment(picture_tag).children[0]
            expect(tag.name).to eq('picture')
            expect(tag.css('img')[0].attribute('src').value).to start_with("https://assets.imgix.net")
          end

          it 'with explicit source supplied' do
            picture_tag = helper.ix_picture_tag(
              'assets2.imgix.net',
              'bertandernie.jpg',
              tag_options: tag_options,
              url_params: url_params,
              breakpoints: breakpoints,
            )
            tag = Nokogiri::HTML.fragment(picture_tag).children[0]
            expect(tag.name).to eq('picture')
            expect(tag.css('img')[0].attribute('src').value).to start_with("https://assets2.imgix.net")
          end
        end

        describe 'passes through options to the `picture`' do
          it 'with no source supplied' do
            picture_tag = helper.ix_picture_tag(
              'bertandernie.jpg',
              tag_options: tag_options,
              url_params: url_params,
              breakpoints: breakpoints,
            )
            tag = Nokogiri::HTML.fragment(picture_tag).children[0]
            expect(tag.attribute('class').value).to eq('a-picture-tag')
          end

          it 'with explicit source supplied' do
            picture_tag = helper.ix_picture_tag(
              'assets2.imgix.net',
              'bertandernie.jpg',
              tag_options: tag_options,
              url_params: url_params,
              breakpoints: breakpoints,
            )
            tag = Nokogiri::HTML.fragment(picture_tag).children[0]
            url = tag.css('img')[0].attribute('src').value

            # tag_options
            expect(tag.attribute('class').value).to eq('a-picture-tag')

            # url_params
            expect(url).to include("w=300")
            expect(url).to include("h=300")
            expect(url).to include("fit=crop")

            # breakpoints
            expected_media = [
              '(max-width: 640px)',
              '(max-width: 880px)',
              '(min-width: 881px)'
            ]
            tag.css('source').each_with_index do |source, i|
              expect(source.attribute('media').value).to eq(expected_media[i])
            end
          end
        end
      end

      it 'raises error for unknown source' do
        expect{
          helper.ix_image_url("foo.bar", "image.jpg")
        }.to raise_error(RuntimeError)
      end
    end

    describe 'no default_source specified' do
      let(:app) { Class.new(::Rails::Application) }
      let(:sources) { { "assets.imgix.net" => nil, "assets2.imgix.net" => nil } }

      before do
        Imgix::Rails.configure { |config| config.imgix = { sources: sources } }
      end

      describe '#ix_image_url' do
        it 'raises error when no source is supplied' do
          expect{
            helper.ix_image_url("image.jpg")
          }.to raise_error(RuntimeError)
        end

        it "doesn't raise error when source is supplied" do
          expect{
            helper.ix_image_url("assets2.imgix.net", "image.jpg")
          }.not_to raise_error
        end
      end

      describe '#ix_image_tag' do
        it 'raises error when no source is supplied' do
          expect{
            helper.ix_image_tag("image.jpg")
          }.to raise_error(RuntimeError)
        end

        it "doesn't raise error when source is supplied" do
          expect{
            helper.ix_image_tag("assets2.imgix.net", "image.jpg")
          }.not_to raise_error
        end
      end

      describe '#ix_picture_tag' do
        let(:tag_options) { { class: 'a-picture-tag' } }
        let(:url_params) { {
              w: 300,
              h: 300,
              fit: 'crop',
            } }
        let(:breakpoints) { {
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
            } }

        it 'raises error when no source is supplied' do
          expect{
            helper.ix_picture_tag(
              'bertandernie.jpg',
              tag_options: tag_options,
              url_params: url_params,
              breakpoints: breakpoints,
            )
          }.to raise_error(RuntimeError)
        end

        it "doesn't raise error when source is supplied" do
          expect{
            helper.ix_picture_tag(
              'assets2.imgix.net',
              'bertandernie.jpg',
              tag_options: tag_options,
              url_params: url_params,
              breakpoints: breakpoints,
            )
          }.not_to raise_error
        end
      end

      it 'raises error for unknown source' do
        expect{
          helper.ix_image_url("foo.bar", "image.jpg")
        }.to raise_error(RuntimeError)
      end
    end
  end
end
