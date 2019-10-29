[![imgix logo](https://assets.imgix.net/imgix-logo-web-2014.pdf?page=2&fm=png&w=200&h=200)](https://imgix.com)

# imgix-rails [![Build Status](https://travis-ci.org/imgix/imgix-rails.svg?branch=master)](https://travis-ci.org/imgix/imgix-rails)

`imgix-rails` is a gem designed to make integrating imgix into your Rails app easier. It builds on [imgix-rb](https://github.com/imgix/imgix-rb) to offer a few Rails-specific interfaces.

imgix is a real-time image processing service and CDN. It allows you to manipulate images merely by changing their URL parameters. For a full list of URL parameters, please see the [imgix URL API documentation](https://www.imgix.com/docs/reference).

We recommend using something like [Paperclip](https://github.com/thoughtbot/paperclip), [Refile](https://github.com/refile/refile), [Carrierwave](https://github.com/carrierwaveuploader/carrierwave), or [Active Storage](https://github.com/rails/rails/tree/master/activestorage) to handle uploads. After they've been uploaded, you can then serve them using this gem.

* [Installation](#installation)
* [Usage](#usage)
  * [Configuration](#configuration)
  * [ix_image_tag](#ix_image_tag)
  * [ix_picture_tag](#ix_picture_tag)
  * [ix_image_url](#ix_image_url)
    * [Usage in Sprockets](#usage-in-sprockets)
* [Using With Image Uploading Libraries](#using-with-image-uploading-libraries)
  * [Paperclip and CarrierWave](#paperclip-and-carrierwave)
  * [Refile](#refile)
  * [Active Storage](#activestorage)
* [Development](#development)
* [Contributing](#contributing)


<a name="installation"></a>
## Installation

Add this line to your application's Gemfile:

```ruby
gem 'imgix-rails'
```

And then execute:

    $ bundle


<a name="usage"></a>
## Usage

imgix-rails provides a few different hooks to work with your existing Rails application. All current methods are drop-in replacements for the `image_tag` helper.

<a name="configuration"></a>
### Configuration

Before you get started, you will need to define your imgix configuration in your `config/application.rb`, or in an environment-specific configuration file.

```ruby
Rails.application.configure do
  config.imgix = {
    source: "assets.imgix.net"
  }
end
```

The following configuration flags will be respected:

- `:use_https` toggles the use of HTTPS. Defaults to `true`
- `:source` a String or Array that specifies the imgix Source address. Should be in the form of `"assets.imgix.net"`.
- `:srcset_width_tolerance` an optional numeric value determining the maximum tolerance allowable, between the downloaded dimensions and rendered dimensions of the image (default `.08` i.e. `8%`).
- `:secure_url_token` an optional secure URL token found in your dashboard (https://dashboard.imgix.com) used for signing requests

#### Multi-source configuration

In addition to the standard configuration flags, the following options can be used for multi-source support.

- `:sources` a Hash of imgix source-secure_url_token key-value pairs. If the value for a source is `nil`, URLs generated for the corresponding source won't be secured. `:sources` and `:source` *cannot* be used together.
- `:default_source` optionally specify a default source for generating URLs.

Example:

```ruby
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

<a name="ix_image_tag"></a>
### ix_image_tag

The `ix_image_tag` helper method makes it easy to pass parameters to imgix to handle resizing, cropping, etc. It also simplifies adding responsive imagery to your Rails app by automatically generating a `srcset` based on the parameters you pass. We talk a bit about using the `srcset` attribute in an application in the following blog post: [“Responsive Images with `srcset` and imgix.”](https://blog.imgix.com/2015/08/18/responsive-images-with-srcset-imgix.html).

`ix_image_tag` generates `<img>` tags with a filled-out `srcset` attribute that leans on imgix to do the hard work. If you already know the minimum or maximum number of physical pixels that this image will need to be displayed at, you can pass the `min_width` and/or `max_width` options. This will result in a smaller, more tailored `srcset`.

`ix_image_tag` takes the following arguments:

* `source`: an optional String indicating the source to be used. If unspecified `:source` or `:default_source` will be used. If specified, the value must be defined in the config.
* `path`: The path or URL of the image to display.
* `tag_options`: Any options to apply to the generated `img` element. This is useful for adding class names, etc.
* `url_params`: The imgix URL parameters to apply to this image. These will be applied to each URL in the `srcset` attribute, as well as the fallback `src` attribute.

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

```ruby
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
<%= ix_image_tag('/unsplash/hotairballoon.jpg', widths: [320, 640, 960, 1280], url_params: { w: 300, h: 500, fit: 'crop', crop: 'right'}, tag_options: { alt: 'A hot air balloon on a sunny day' }) %>
```


<a name="ix_picture_tag"></a>
### ix_picture_tag

The `ix_picture_tag` helper method makes it easy to generate `picture` elements in your Rails app. `picture` elements are useful when an images needs to be art directed differently at different screen sizes.

`ix_picture_tag` takes the following arguments:

* `source`: an optional String indicating the source to be used. If unspecified `:source` or `:default_source` will be used. If specified, the value must be defined in the config.
* `path`: The path or URL of the image to display.
* `tag_options`: Any options to apply to the parent `picture` element. This is useful for adding class names, etc.
* `url_params`: Default imgix options. These will be used to generate a fallback `img` tag for older browsers, and used in each `source` unless overridden by `breakpoints`.
* `breakpoints`: A hash describing the variants. Each key must be a media query (e.g. `(max-width: 880px)`), and each value must be a hash of parameter overrides for that media query. A `source` element will be generated for each breakpoint specified.

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

<a name="ix_image_url"></a>
### ix_image_url

The `ix_image_url` helper makes it easy to generate a URL to an image in your Rails app.

`ix_image_url` takes four arguments:

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

Since `ix_image_url` lives inside `UrlHelper`, it can also be used in places other than your views quite easily. This is useful for things such as including imgix URLs in JSON output from a serializer class.

```ruby
include Imgix::Rails::UrlHelper

puts ix_image_url('/users/1/avatar.png', { w: 400, h: 300 })
# => https://assets.imgix.net/users/1/avatar.png?w=400&h=300
```

<a name="usage-in-sprockets"></a>
#### Usage in Sprockets

`ix_image_url` is also pulled in as a Sprockets helper, so you can generate imgix URLs in your asset pipeline files. For example, here's how it would work inside an `.scss.erb` file:

```scss
.something {
  background-image: url(<%= ix_image_url('a-background.png', { w: 400, h: 300 }) %>);
}
```

<a name="using-with-image-uploading-libraries"></a>
## Using With Image Uploading Libraries

imgix-rails plays well with image uploading libraries, because it just requires a URL and optional parameters as arguments. A good way to handle this interaction is by creating helpers that bridge between your uploading library of choice and imgix-rails. Below are examples of how this can work with some common libraries. Please submit an issue if you'd like to see specific examples for another!


<a name="paperclip-and-carrierwave"></a>
### Paperclip and CarrierWave

Paperclip and CarrierWave can directly provide paths to uploaded images, so we can use them with imgix-rails without a bridge.

``` html
<%= ix_image_tag(@user.avatar.path, { auto: 'format', fit: 'crop', w: 500}) %>
```


<a name="refile"></a>
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

<a name="activestorage"></a>
### Active Storage

To set up imgix with ActiveStorage, first ensure that the remote source your ActiveStorage service is pointing to is the same as your imgix source — such as an s3 bucket.

#### config/storage.yml
```yml
service: S3
access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
region: us-east-1
bucket: your_own_bucket
```

Modify your active_storage.service setting depending on what environment you are using. For example, to use Amazon s3 in production, make the following change:

#### config/environments/production.rb
```ruby
config.active_storage.service = :amazon
```

As you would normally with imgix-rails, configure your application to point to your imgix source:

#### config/application.rb
```ruby
Rails.application.configure do
      config.imgix = {
        source: your_domain,
        use_https: true,
        include_library_param: true
      }
end
```

Finally, the two can be used together by passing in the filename of the ActiveStorage blob into the imgix-rails helper function:

#### show.html.erb
```erb
<%= ix_image_tag(@your_model.image.key) %>
```

<a name="development"></a>
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


<a name="contributing"></a>
## Contributing

1. Fork it ( https://github.com/[my-github-username]/imgix-rails/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Code of Conduct
Users contributing to or participating in the development of this project are subject to the terms of imgix's [Code of Conduct](https://github.com/imgix/code-of-conduct).
