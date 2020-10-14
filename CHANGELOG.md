# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [4.1.0](https://github.com/imgix/imgix-rb/compare/4.0.2...4.1.0) - October 13, 2020

### Release Notes
Version 4.1.0 has been released! The goal of this release is to offer flexibility to those using imgix-rb's purger capabilities through imgix-rails.

Prior to this release, this gem offered purging capability through `imgix '~> 3.0'`. However, that purging capability has been deprecated in favor of the new-style purging API––available now in [imgix-rb v4.0.0](https://github.com/imgix/imgix-rb/releases/tag/4.0.0).

To upgrade to the new purging API used in `imgix '~> 4.0'`:

- navigate to the [API Keys](https://dashboard.imgix.com/api-keys) portion of your dashboard
- generate a new API Key
- use this new key in your imgix client: `Imgix::Client.new(domain: '...', api_key: NEW_API_KEY)`

### Changes
- build: use optimistic constraint for imgix >= 3.0 ([#104](https://github.com/imgix/imgix-rails/pull/104))

## [4.0.2](https://github.com/imgix/imgix-rb/compare/4.0.1...4.0.2) - July 31, 2020
- fix: replace `opts[:host`] with `opts[:domain]` to resolve deprecation warnings ([#96](https://github.com/imgix/imgix-rails/pull/96))

## [4.0.1](https://github.com/imgix/imgix-rb/compare/4.0.0...4.0.1) - June 10, 2020

- fix: update rake version ([#94](https://github.com/imgix/imgix-rails/pull/94))

## [4.0.0](https://github.com/imgix/imgix-rb/compare/3.1.0...4.0.0) - December 03, 2019

The v4.0.0 release of imgix-rails introduces a variety of improvements relating to how this gem handles and generates `srcset` attributes. However, in releasing this version there are some significant interface/behavioral changes that users need to be aware of. Users should note that the `min_width` and `max_width` fields (passed via `tag_options`), as well as the `widths` field, have all been moved to their own encompassing `srcset_options` field. This is done with the intention of providing a more organized and intuitive experience when fine-tuning how `srcset` width pairs are generated. See the following example demonstrating this new pattern:

```erb
<%= ix_image_tag('/unsplash/hotairballoon.jpg',
  srcset_options: { min_width: 1000, max_width: 2500},
  tag_options: { alt: 'A hot air balloon on a sunny day' }) %>
```

For users migrating to version 4.0 or later, it is important that all srcset-related modifiers be passed via `srcset_options`, as doing so through `tag_options` or `widths` directly will result in errors. For more details on these modifiers, please see the [ix_image_tag](https://github.com/imgix/imgix-rails#ix_image_tag) or [ix_picture_tag](https://github.com/imgix/imgix-rails#ix_picture_tag) sections.

In addition to these changes, imgix-rails is now capable of producing [fixed-image srcsets](https://github.com/imgix/imgix-rb#fixed-image-rendering). Users should note that when certain dimension information is provided, imgix-rails will produce a `srcset` at different screen resolutions rather than the typical width pairs. This feature provides expanded functionality to cover more `srcset` use cases that users can take advantage of. We are always happy to provide our users with more tools to assist them in their efforts to build out responsive images on the web.

* feat: utilize Imgix::Path#to_srcset when constructing srcsets ([#83](https://github.com/imgix/imgix-rails/pull/83))
* chore: remove deprecated domain sharding behavior ([#80](https://github.com/imgix/imgix-rails/pull/80))
* fix: deprecate resizing height when maintaining aspect ratio ([#78](https://github.com/imgix/imgix-rails/pull/78))

## [3.1.0](https://github.com/imgix/imgix-rb/compare/3.0.2...3.1.0) - October 25, 2019

* Update bundler dev dependency to include new major version 2.x ([#71](https://github.com/imgix/imgix-rb/pull/71))
* README: Fix typo ([#73](https://github.com/imgix/imgix-rb/pull/73))
* docs: add ActiveStorage instructions to README ([#74](https://github.com/imgix/imgix-rb/pull/74))
* chore(deprecate): emit warning when generating srcsets ([ccc906b](https://github.com/imgix/imgix-rails/commit/ccc906be749945f6f843b5eeb04ab03a292ccbfb)) ([e2ffc2b](https://github.com/imgix/imgix-rails/commit/e2ffc2b4f847c15ea73fa161b673885e704e4cf2))
