<!-- ix-docs-ignore -->
![imgix logo](https://assets.imgix.net/sdk-imgix-logo.svg)

`imgix-rails` is a gem for integrating [imgix](https://www.imgix.com/) into Ruby on Rails applications. It builds on [imgix-rb](https://github.com/imgix/imgix-rb) to offer a few Rails-specific interfaces.

[![Gem Version](https://img.shields.io/gem/v/imgix-rails.svg)](https://rubygems.org/gems/imgix-rails)
[![Build Status](https://travis-ci.org/imgix/imgix-rails.svg?branch=main)](https://travis-ci.org/imgix/imgix-rails)
![Downloads](https://img.shields.io/gem/dt/imgix-rails)
[![License](https://img.shields.io/github/license/imgix/imgix-rails)](https://github.com/imgix/imgix-rails/blob/main/LICENSE)

---
<!-- /ix-docs-ignore -->

- [Installation](#installation)
- [Usage](#usage)
  - [Configuration](#configuration)
    - [Multi-source configuration](#multi-source-configuration)
  - [`ix_image_tag`](#iximagetag)
    - [Fixed image rendering](#fixed-image-rendering)
    - [Lazy Loading](#lazy-loading)
  - [`ix_picture_tag`](#ixpicturetag)
  - [`ix_image_url`](#iximageurl)
    - [Usage in Model](#usage-in-model)
    - [Usage in Sprockets](#usage-in-sprockets)
- [Using With Image Uploading Libraries](#using-with-image-uploading-libraries)
  - [Paperclip and CarrierWave](#paperclip-and-carrierwave)
  - [Refile](#refile)
  - [Active Storage](#active-storage)
    - [S3](#s3)
    - [GCS](#gcs)
- [Upgrade Guides](#upgrade-guides)
  - [3.x to 4.0](#3x-to-40)
- [Development](#development)
- [Contributing](#contributing)
- [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```rb
gem 'imgix-rails'
```

And then execute:

```bash
$ bundle
```

## Usage

imgix-rails provides a few different hooks to work with your existing Rails application. All current methods are drop-in replacements for the `image_tag` helper.

### Configuration

Before you get started, you will need to define your imgix configuration in your `config/application.rb`, or in an environment-specific configuration file.

```rb
Rails.application.configure do
  config.imgix = {
    source: "assets.imgix.net"
  }
end
```

The following configuration flags will be respected:

- `use_https`: toggles the use of HTTPS. Defaults to `true`
- `source`: a String or Array that specifies the imgix Source address. Should be in the form of `"assets.imgix.net"`.
- `srcset_width_tolerance`: an optional numeric value determining the maximum tolerance allowable, between the downloaded dimensions and rendered dimensions of the image (default `0.08` i.e. `8%`).
- `secure_url_token`: an optional secure URL token found in your dashboard (https://dashboard.imgix.com) used for signing requests
- `include_library_param`: toggles the inclusion of the [`ixlib` parameter](https://github.com/imgix/imgix-rb#what-is-the-ixlib-param-on-every-request). Defaults to `true`.

#### Multi-source configuration

In addition to the standard configuration flags, the following options can be used for multi-source support.

- `sources`: a Hash of imgix source-secure_url_token key-value pairs. If the value for a source is `nil`, URLs generated for the corresponding source won't be secured. `sources` and `source` *cannot* be used together.
- `default_source`: optionally specify a default source for generating URLs.

Example:

```rb
Rails.application.configure do
  config.imgix = {
    sources: {
      "assets.imgix.net"  => "foobarbaz",
      "assets2.imgix.net" => nil,   # Will generate unsigned URLs
    },
    default_source: "assets.imgix.net"
  }
end
```

### `ix_image_tag`

The `ix_image_tag` helper method makes it easy to pass parameters to imgix to handle resizing, cropping, etc. It also simplifies adding responsive imagery to your Rails app by automatically generating a `srcset` based on the parameters you pass. We talk a bit about using the `srcset` attribute in an application in the following blog post: [“Responsive Images with `srcset` and imgix.”](https://docs.imgix.com/tutorials/responsive-images-srcset-imgix?_ga=utm_medium=referral&utm_source=sdk&utm_campaign=rails-readme).

`ix_image_tag` generates `<img>` tags with a filled-out `srcset` attribute that leans on [imgix-rb](https://github.com/imgix/imgix-rb) to do the hard work. It also makes a variety of options available for customizing how the `srcset` is generated. For example, if you already know the minimum or maximum number of physical pixels that this image will need to be displayed at, you can pass the `min_width` and/or `max_width` options. This will result in a smaller, more tailored `srcset`.

`ix_image_tag` takes the following arguments:

* `source`: An optional String indicating the source to be used. If unspecified `:source` or `:default_source` will be used. If specified, the value must be defined in the config.
* `path`: The path or URL of the image to display.
* `tag_options`: HTML attributes to apply to the generated `img` element. This is useful for adding class names, alt tags, etc.
* `url_params`: The imgix URL parameters to apply to this image. These will be applied to each URL in the `srcset` attribute, as well as the fallback `src` attribute.
* `srcset_options`: A variety of options that allow for fine tuning `srcset` generation. More information on each of these modifiers can be found in the [imgix-rb documentation](https://github.com/imgix/imgix-rb#srcset-generation). Any of the following can be passed as arguments:
  * [`widths`](https://github.com/imgix/imgix-rb#custom-widths): An array of exact widths that `srcset` pairs will be generated with.
  * [`min_width`](https://github.com/imgix/imgix-rb#minimum-and-maximum-width-ranges): The minimum width that `srcset` pairs will be generated with. Will be ignored if `widths` are provided.
  * [`max_width`](https://github.com/imgix/imgix-rb#minimum-and-maximum-width-ranges): The maximum width that `srcset` pairs will be generated with. Will be ignored if `widths` are provided.
  * [`disable_variable_quality`](https://github.com/imgix/imgix-rb#variable-qualities): Pass `true` to disable variable quality parameters when generating a `srcset` ([fixed-images only](https://github.com/imgix/imgix-rails#fixed-image-rendering)). In addition, imgix-rails will respect an overriding `q` (quality) parameter if one is provided through `url_params`.
  * `attribute_options`: Allow you to change where imgix-rails renders
    attributes. This can be helpful if you want to add lazy-loading.

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg', url_params: { w: 300, h: 500, fit: 'crop', crop: 'right'}, tag_options: { alt: 'A hot air balloon on a sunny day' }) %>
```

Will render out HTML like the following:

```html
<img
  alt="A hot air balloon on a sunny day"
  sizes="100vw"
  srcset="
    https://assets.imgix.net/unsplash/hotairballoon.jpg?w=100&amp;h=167&amp;fit=crop&amp;crop=right 100w,
    https://assets.imgix.net/unsplash/hotairballoon.jpg?w=200&amp;h=333&amp;fit=crop&amp;crop=right 200w,
    …
    https://assets.imgix.net/unsplash/hotairballoon.jpg?w=2560&amp;h=4267&amp;fit=crop&amp;crop=right 2560w
  "
  src="https://assets.imgix.net/unsplash/hotairballoon.jpg?w=300&amp;h=500&amp;fit=crop&amp;crop=right"
>
```

Similarly

```erb
<%= ix_image_tag('assets2.imgix.net', '/unsplash/hotairballoon.jpg') %>
```

Will generate URLs using `assets2.imgix.net` source.

We recommend leveraging this to generate powerful helpers within your application like the following:

```rb
def profile_image_tag(user)
  ix_image_tag(user.profile_image_url, url_params: { w: 100, h: 200, fit: 'crop' })
end
```

Then rendering the portrait in your application is very easy:

```erb
<%= profile_image_tag(@user) %>
```

If you already know all the exact widths you need images for, you can specify that by passing the `widths` option as an array. In this case, imgix-rails will only generate `srcset` pairs for the specified `widths`.

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg', srcset_options: { widths: [320, 640, 960, 1280] }, tag_options: { alt: 'A hot air balloon on a sunny day' }) %>
```

#### Fixed image rendering

In cases where enough information is provided about an image's dimensions, `ix_image_tag` will instead build a `srcset` that will allow for an image to be served at different resolutions. The parameters taken into consideration when determining if an image is fixed-width are `w`, `h`, and `ar`. By invoking `ix_image_tag` with either a width or the height and aspect ratio (along with `fit=crop`, typically) provided, a different srcset will be generated for a fixed-size image instead.

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg', url_params: {w: 1000}) %>
```

Will render the following HTML:

```html
<img srcset="https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=1&amp;q=75 1x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=2&amp;q=50 2x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=3&amp;q=35 3x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=4&amp;q=23 4x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=5&amp;q=20 5x" sizes="100vw" src="https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000">
```

Fixed image rendering will automatically append a variable `q` parameter mapped to each `dpr` parameter when generating a `srcset`. This technique is commonly used to compensate for the increased filesize of high-DPR images. Since high-DPR images are displayed at a higher pixel density on devices, image quality can be lowered to reduce overall filesize without sacrificing perceived visual quality. For more information and examples of this technique in action, see [this blog post](https://blog.imgix.com/2016/03/30/dpr-quality?_ga=utm_medium=referral&utm_source=sdk&utm_campaign=rails-readme). This behavior will respect any overriding `q` value passed in via `url_params` and can be disabled altogether with `srcset_options: { disable_variable_quality: true }`.

#### Lazy loading

If you'd like to lazy load images, we recommend using [lazysizes](https://github.com/aFarkas/lazysizes). In order to use imgix-rails with lazysizes, you need to use `attribute_options` as well as set `tag_options[:src]`:

```erb
<%= ix_image_tag('image.jpg', attribute_options: {src: "data-src",
srcset: "data-srcset", sizes: "data-sizes"}, url_params: {w: 1000},
tag_options: {src: "lqip.jpg"}) %>
```

Will render the following HTML:

```html
<img data-srcset="https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=1&amp;q=75 1x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=2&amp;q=50 2x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=3&amp;q=35 3x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=4&amp;q=23 4x,
https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000&amp;dpr=5&amp;q=20 5x"
data-sizes="100vw"
data-src="https://assets.imgix.net/image.jpg?ixlib=rails-3.0.2&amp;w=1000"
src="lqip.jpg">
```

### `ix_picture_tag`

The `ix_picture_tag` helper method makes it easy to generate `picture` elements in your Rails app. `picture` elements are useful when an images needs to be art directed differently at different screen sizes.

`ix_picture_tag` takes the following arguments:

* `source`: an optional String indicating the source to be used. If unspecified `:source` or `:default_source` will be used. If specified, the value must be defined in the config.
* `path`: The path or URL of the image to display.
* `tag_options`: Any options to apply to the parent `picture` element. This is useful for adding class names, etc.
* `url_params`: Default imgix options. These will be used to generate a fallback `img` tag for older browsers, and used in each `source` unless overridden by `breakpoints`.
* `breakpoints`: A hash describing the variants. Each key must be a media query (e.g. `(max-width: 880px)`), and each value must be a hash of parameter overrides for that media query. A `source` element will be generated for each breakpoint specified.
* `srcset_options`: A variety of options that allow for fine tuning `srcset` generation. More information on each of these modifiers can be found in the [imgix-rb documentation](https://github.com/imgix/imgix-rb#srcset-generation). Any of the following can be passed as arguments:
  * [`widths`](https://github.com/imgix/imgix-rb#custom-widths): An array of exact widths that `srcset` pairs will be generated with.
  * [`min_width`](https://github.com/imgix/imgix-rb#minimum-and-maximum-width-ranges): The minimum width that `srcset` pairs will be generated with. Will be ignored if `widths` are provided.
  * [`max_width`](https://github.com/imgix/imgix-rb#minimum-and-maximum-width-ranges): The maximum width that `srcset` pairs will be generated with. Will be ignored if `widths` are provided.
  * [`disable_variable_quality`](https://github.com/imgix/imgix-rb#variable-qualities): Pass `true` to disable variable quality parameters when generating a `srcset` ([fixed-images only](https://github.com/imgix/imgix-rails#fixed-image-rendering)). In addition, imgix-rails will respect an overriding `q` (quality) parameter if one is provided through `url_params`.

```erb
<%= ix_picture_tag('bertandernie.jpg',
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
      url_params: {
        h: 100,
      },
      tag_options: {
        sizes: 'calc(100vw - 20px)'
      }
    },
    '(max-width: 880px)' => {
      url_params: {
        crop: 'right',
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
) %>
```

To generate a `picture` element on a different source:

```erb
<%= ix_picture_tag('assets2.imgix.net', 'bertandernie.jpg',
      tag_options: {},
      url_params: {},
      breakpoints: {
        '(max-width: 640px)' => {
          url_params: { h: 100 },
          tag_options: { sizes: 'calc(100vw - 20px)' }
        },
      }
   ) %>
```

### `ix_image_url`

The `ix_image_url` helper makes it easy to generate a URL to an image in your Rails app.

`ix_image_url` takes three arguments:

* `source`: an optional String indicating the source to be used. If unspecified `:source` or `:default_source` will be used. If specified, the value must be defined in the config.
* `path`: The path or URL of the image to display.
* `options`: The imgix URL parameters to apply to this image URL.

```erb
<%= ix_image_url('/users/1/avatar.png', { w: 400, h: 300 }) %>
<%= ix_image_url('assets2.imgix.net', '/users/1/avatar.png', { w: 400, h: 300 }) %>
```

Will generate the following URLs:

```html
https://assets.imgix.net/users/1/avatar.png?w=400&h=300
https://assets2.imgix.net/users/1/avatar.png?w=400&h=300
```

#### Usage in Model

Since `ix_image_url` lives inside `UrlHelper`, it can also be used in places other than your views quite easily. This is useful for things such as including imgix URLs in JSON output from a serializer class.

```rb
include Imgix::Rails::UrlHelper

puts ix_image_url('/users/1/avatar.png', { w: 400, h: 300 })
# => https://assets.imgix.net/users/1/avatar.png?w=400&h=300
```

Alternatively, you can also use the imgix [Ruby client](https://github.com/imgix/imgix-rb) in the same way.

#### Usage in Sprockets

`ix_image_url` is also pulled in as a Sprockets helper, so you can generate imgix URLs in your asset pipeline files. For example, here's how it would work inside an `.scss.erb` file:

```scss
.something {
  background-image: url(<%= ix_image_url('a-background.png', { w: 400, h: 300 }) %>);
}
```

## Using With Image Uploading Libraries

imgix-rails plays well with image uploading libraries, because it just requires a URL and optional parameters as arguments. A good way to handle this interaction is by creating helpers that bridge between your uploading library of choice and imgix-rails. Below are examples of how this can work with some common libraries. Please submit an issue if you'd like to see specific examples for another!

### Paperclip and CarrierWave

Paperclip and CarrierWave can directly provide paths to uploaded images, so we can use them with imgix-rails without a bridge.

``` html
<%= ix_image_tag(@user.avatar.path, { auto: 'format', fit: 'crop', w: 500}) %>
```

### Refile

Since Refile doesn't actually store URLs or paths in the database (instead using a "prefix" + image identifier), the basic setup is slightly different. In this case, we use a couple helpers that bridge between Refile and imgix-rails.

``` ruby
module ImgixRefileHelper
  def ix_refile_image_url(obj, key, **opts)
    path = s3_path(obj, key)
    path ? ix_image_url(path, opts) : ''
  end

  def ix_refile_image_tag(obj, key, **opts)
    path = s3_path(obj, key)
    path ? ix_image_tag(path, opts) : ''
  end

private
  def s3_path(obj, key)
    refile_id = obj["#{key}_id"]
    s3_prefix = obj.send(key).try(:backend).instance_variable_get(:@prefix)

    s3_prefix ? "#{s3_prefix}/#{refile_id}" : nil
  end
end
```

``` html
<%= ix_refile_image_tag(@blog_post, :hero_photo, {auto: 'format', fit: 'crop', w: 500}) %>
```

### Active Storage

To set up imgix with ActiveStorage, first ensure that the remote source your ActiveStorage service is pointing to is the same as your imgix source — such as an s3 bucket.

### S3 
**config/storage.yml**

```yml
service: S3
access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
region: us-east-1
bucket: your_own_bucket
```

### GCS 
```yml
google:
  service: GCS
  project: Project Name
  credentials: <%= Rails.root.join("path/to/key.json") %>
  bucket: Bucket Name
```

Modify your `active_storage.service` setting depending on what environment you are using. For example, to use Amazon s3 in production, make the following change:

**config/environments/production.rb**

```rb
config.active_storage.service = :amazon
```

To use Google GCS in production, configure the active storage service like so:

```rb
config.active_storage.service = :google
```

As you would normally with imgix-rails, configure your application to point to your imgix source:

**config/application.rb**

```rb
Rails.application.configure do
      config.imgix = {
        source: your_domain,
        use_https: true,
        include_library_param: true
      }
end
```

Finally, the two can be used together by passing in the filename of the ActiveStorage blob into the imgix-rails helper function:

**show.html.erb**

```erb
<%= ix_image_tag(@your_model.image.key) %>
```

## Upgrade Guides

### 3.x to 4.0

The v4.0.0 release of imgix-rails introduces a variety of improvements relating to how this gem handles and generates `srcset` attributes. However, in releasing this version there are some significant interface/behavioral changes that users need to be aware of. Users should note that the `min_width` and `max_width` fields (passed via `tag_options`), as well as the `widths` field, have all been moved to their own encompassing `srcset_options` field. This is done with the intention of providing a more organized and intuitive experience when fine-tuning how `srcset` width pairs are generated. See the following example demonstrating this new pattern:

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg',
  srcset_options: { min_width: 1000, max_width: 2500},
  tag_options: { alt: 'A hot air balloon on a sunny day' }) %>
```

For users migrating to version 4.0 or later, it is important that all srcset-related modifiers be passed via `srcset_options`, as doing so through `tag_options` or `widths` directly will result in errors. For more details on these modifiers, please see the [ix_image_tag](https://github.com/imgix/imgix-rails#ix_image_tag) or [ix_picture_tag](https://github.com/imgix/imgix-rails#ix_picture_tag) sections.

In addition to these changes, imgix-rails is now capable of producing [fixed-image srcsets](https://github.com/imgix/imgix-rb#fixed-image-rendering). Users should note that when certain dimension information is provided, imgix-rails will produce a `srcset` at different screen resolutions rather than the typical width pairs. This feature provides expanded functionality to cover more `srcset` use cases that users can take advantage of. We are always happy to provide our users with more tools to assist them in their efforts to build out responsive images on the web.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/imgix-rails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Code of Conduct
Users contributing to or participating in the development of this project are subject to the terms of imgix's [Code of Conduct](https://github.com/imgix/code-of-conduct).
