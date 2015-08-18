require 'spec_helper'
require 'imgix/rails/view_helper'

helper = Class.new do
  include Imgix::Rails::ViewHelper
end.new

describe Imgix::Rails do
  it 'has a version number' do
    expect(Imgix::Rails::VERSION).not_to be nil
  end

  it 'pulls in imgix-rb' do
    expect(Imgix::VERSION).not_to be nil
  end

  describe 'configuration' do
    it 'expects config.imgix.source to be defined'
    it 'expects config.imgix.source to be a String or an Array'
    it 'optionally expects config.imgix.secure_url_token to be defined'
  end

  describe Imgix::Rails::ViewHelper do
    it 'returns 1' do
      expect(helper.returns_1).to eq 1
    end

    it 'signs image URLs with ixlib=rails'

    describe '#ix_image_tag'
    describe '#ix_responsive_image_tag'
    describe '#ix_picture_tag'
  end
end
