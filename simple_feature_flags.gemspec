# frozen_string_literal: true

require_relative 'lib/simple_feature_flags/version'

::Gem::Specification.new do |spec|
  spec.name          = "simple_feature_flags"
  spec.version       = ::SimpleFeatureFlags::VERSION
  spec.authors       = ["Espago", "Mateusz Drewniak"]
  spec.email         = ["m.drewniak@espago.com"]

  spec.summary       = "Simple feature flag functionality for your Ruby/Rails/Sinatra app!"
  spec.description   = "A simple Ruby gem which lets you dynamically enable/disable parts of your code using Redis or your server's RAM!"
  spec.homepage      = "https://github.com/espago/simple_feature_flags"
  spec.license       = "MIT"
  spec.required_ruby_version = ::Gem::Requirement.new(">= 2.5.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/espago/simple_feature_flags"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = ::Dir.chdir(::File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| ::File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'bundler-audit'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'solargraph'
end
