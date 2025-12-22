# frozen_string_literal: true

require_relative "lib/bookworm/version"

Gem::Specification.new do |s|
  s.name          = "bookworm"
  s.version       = Bookworm::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Dmitry Vorotilin"]
  s.email         = ["d.vorotilin@gmail.com"]
  s.summary       = "Read kinesis like a bookworm"
  s.description   = "Read kinesis like a bookworm."
  s.homepage      = "https://github.com/SinceraIO/bookworm"
  s.license       = "MIT"
  s.require_paths = ["lib"]
  s.files         = Dir["lib/**/*", "LICENSE", "README.md"]
  s.metadata = {
    "homepage_uri" => s.homepage,
    "bug_tracker_uri" => "https://github.com/SinceraIO/bookworm/issues",
    "documentation_uri" => "https://github.com/SinceraIO/bookworm/blob/main/README.md",
    "changelog_uri" => "https://github.com/SinceraIO/bookworm/blob/main/CHANGELOG.md",
    "source_code_uri" => "https://github.com/SinceraIO/bookworm",
    "rubygems_mfa_required" => "true"
  }

  s.required_ruby_version = ">= 3.1.0"

  s.add_dependency "aws-sdk-kinesis", "~> 1.93"
  s.add_dependency "concurrent-ruby", "~> 1"
  s.add_dependency "redis", ">= 4.0.1"
end
