[![imgix logo](https://assets.imgix.net/imgix-logo-web-2014.pdf?page=2&fm=png&w=200&h=200)](https://imgix.com)

# imgix-rails [![Build Status](https://travis-ci.org/imgix/imgix-rails.svg?branch=master)](https://travis-ci.org/imgix/imgix-rails) [![Slack Status](http://slack.imgix.com/badge.svg)](http://slack.imgix.com)

`imgix-rails` is a gem designed to make integrating imgix into your Rails app easier. It builds on [imgix-rb](https://github.com/imgix/imgix-rb) to offer a few Rails-specific interfaces.

imgix is a real-time image processing service and CDN. It allows you to manipulate images merely by changing their URL parameters. For a full list of URL parameters, please see the [imgix URL API documentation](https://www.imgix.com/docs/reference).

We recommend using something like [Paperclip](https://github.com/thoughtbot/paperclip), [Refile](https://github.com/refile/refile), [Carrierwave](https://github.com/carrierwaveuploader/carrierwave), or [s3_direct_upload](https://github.com/waynehoover/s3_direct_upload) to handle uploads. After they've been uploaded, you can then serve them using this gem.

* [Installation](#installation)
* [Usage](#usage)
  * [Configuration](#configuration)
  * [ix_image_tag](#ix_image_tag)
  * [ix_picture_tag](#ix_picture_tag)
  * [ix_image_url](#ix_image_url)
    * [Usage in Sprockets](#usage-in-sprockets)
  * [Hostname Removal](#hostname-removal)
* [Using With Image Uploading Libraries](#using-with-image-uploading-libraries)
  * [Paperclip and CarrierWave](#paperclip-and-carrierwave)
  * [Refile](#refile)
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
    source: "Name of your source, e.g. assets.imgix.net"
  }
end
```

The following configuration flags will be respected:

- `:use_https` toggles the use of HTTPS. Defaults to `true`
- `:source` a String or Array that specifies the imgix Source address. Should be in the form of `"assets.imgix.net"`.
- `:secure_url_token` a optional secure URL token found in your dashboard (https://webapp.imgix.com) used for signing requests
- `:hostnames_to_replace` an Array of hostnames to replace with the value(s) specified by `:source`. This is useful if you store full-qualified S3 URLs in your database, but want to serve images through imgix.

<a name="ix_image_tag"></a>
### ix_image_tag

The `ix_image_tag` helper method makes it easy to pass parameters to imgix to handle resizing, cropping, etc. It also simplifies adding responsive imagery to your Rails app by automatically generating a `srcset` based on the parameters you pass. We talk a bit about using the `srcset` attribute in an application in the following blog post: [“Responsive Images with `srcset` and imgix.”](https://blog.imgix.com/2015/08/18/responsive-images-with-srcset-imgix.html).

`ix_image_tag` generates `<img>` tags with a filled-out `srcset` attribute that leans on imgix to do the hard work. If you already know the minimum or maximum number of physical pixels that this image will need to be displayed at, you can pass the `min_width` and/or `max_width` options. This will result in a smaller, more tailored `srcset`.

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg', { w: 300, h: 500, fit: 'crop', crop: 'right', alt: 'A hot air balloon on a sunny day' }) %>
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

We recommend leveraging this to generate powerful helpers within your application like the following:

```ruby
def profile_image_tag(user)
  ix_image_tag(user.profile_image_url, { w: 100, h: 200, fit: 'crop' })
end
```

Then rendering the portrait in your application is very easy:

```erb
<%= profile_image_tag(@user) %>
```

If you already know all the exact widths you need images for, you can specify that by passing the `widths` option as an array. In this case, imgix-rails will only generate `srcset` pairs for the specified `widths`.

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg', { widths: [320, 640, 960, 1280] w: 300, h: 500, fit: 'crop', crop: 'right', alt: 'A hot air balloon on a sunny day' }) %>
```


<a name="ix_picture_tag"></a>
### ix_picture_tag

The `ix_picture_tag` helper method makes it easy to generate `picture` elements in your Rails app. `picture` elements are useful when an images needs to be art directed differently at different screen sizes.

`ix_picture_tag` takes four arguments:

* `source`: The path or URL of the image to display.
* `picture_tag_options`: Any options to apply to the parent `picture` element. This is useful for adding class names, etc.
* `imgix_default_options`: Default imgix options. These will be used to generate a fallback `img` tag for older browsers, and used in each `source` unless overridden by `breakpoints`.
* `breakpoints`: A hash describing the variants. Each key must be a media query (e.g. `(max-width: 880px)`), and each value must be a hash of param overrides for that media query. A `source` element will be generated for each breakpoint specified.

```erb
<%= ix_picture_tag('bertandernie.jpg',
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
) %>
```


<a name="ix_image_url"></a>
### ix_image_url

The `ix_image_url` helper makes it easy to generate a URL to an image in your Rails app.

```erb
<%= ix_image_url('/users/1/avatar.png', { w: 400, h: 300 }) %>
```

Will generate the following URL:

```html
https://assets.imgix.net/users/1/avatar.png?w=400&h=300
```

Since `ix_image_url` lives inside `UrlHelper`, it can also be used in places other than your views quite easily. This is useful for things such as including imgix URLs in JSON output from a serializer class.

```ruby
include Imgix::Rails::UrlHelper

puts ix_image_url('/users/1/avatar.png', { w: 400, h: 300 })
# => https://assets.imgix.net/users/1/avatar.png?w=400&h=300
```

<a name="usage-in-sprockets"></a>
#### Usage in Sprockets

`ix_image_url` is also pulled in as a Sprockets helper, so you can generate imgix URLs in your asset pipline files. For example, here's how it would work inside an `.scss.erb` file:

```scss
.something {
  background-image: url(<%= ix_image_url('a-background.png', { w: 400, h: 300 }) %>);
}
```

### Hostname Removal

You can also configure imgix-rails to disregard given hostnames and only use the path component from given URLs. This is useful if you have [a Web Folder or an Amazon S3 imgix Source configured](https://www.imgix.com/docs/tutorials/creating-sources) but store the fully-qualified URLs for those resources in your database.

For example, let's say you are using S3 for storage. An `#avatar_url` value might look like the following in your application:

```ruby
@user.avatar_url #=> "https://s3.amazonaws.com/my-bucket/users/1.png"
```

You would then configure imgix in your Rails application to disregard the `'s3.amazonaws.com'` hostname:

```ruby
Rails.application.configure do
  config.imgix = {
    source: "my-imgix-source.imgix.net",
    hostname_to_replace: "s3.amazonaws.com"
  }
end
```

Now when you call `ix_image_tag` or another helper, you get an imgix URL:

```erb
<%= ix_image_tag(@user.avatar_url) %>
```

Renders:

```html
<img src="https://my-imgix-source.imgix.net/my-bucket/users/1.png" />
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
