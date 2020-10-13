# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'imgix/rails/version'

Gem::Specification.new do |spec|
  spec.name          = "imgix-rails"
  spec.version       = Imgix::Rails::VERSION
  spec.authors       = ["Kelly Sutton", "Paul Straw"]
  spec.email         = ["kelly@imgix.com", "ixemail"]
  spec.licenses      = ["BSD-2-Clause"]

  spec.summary       = %q{Makes integrating imgix into your Rails app easier. It builds on imgix-rb to offer a few Rails-specific interfaces.}
  spec.description   = %q{Makes integrating imgix into your Rails app easier. It builds on imgix-rb to offer a few Rails-specific interfaces. Please see https://github.com/imgix/imgix-rails for more details.}
  spec.homepage      = "https://github.com/imgix/imgix-rails"

  spec.metadata = {
    'bug_tracker_uri'   => 'https://github.com/imgix/imgix-rails/issues',
    'changelog_uri'     => 'https://github.com/imgix/imgix-rails/blob/main/CHANGELOG.md',
    'documentation_uri' => "https://www.rubydoc.info/gems/imgix-rails/#{spec.version}",
    'source_code_uri'   => "https://github.com/imgix/imgix-rails/tree/v#{spec.version}"
  }
  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "imgix", ">= 3.0"

  spec.add_development_dependency "bundler", ">=1.9"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
end
