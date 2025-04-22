# frozen_string_literal: true

require_relative 'lib/simple_feature_flags/version'

::Gem::Specification.new do |spec|
  spec.name          = 'simple_feature_flags'
  spec.version       = ::SimpleFeatureFlags::VERSION
  spec.authors       = ['Espago', 'Mateusz Drewniak']
  spec.email         = ['m.drewniak@espago.com']

  spec.summary       = 'Simple feature flag functionality for your Ruby/Rails/Sinatra app!'
  spec.description   = <<~DESC
    A simple Ruby gem which lets you dynamically enable/disable parts of your code using Redis or your server's RAM!
  DESC
  spec.homepage      = 'https://github.com/espago/simple_feature_flags'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/espago/simple_feature_flags'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = ::Dir.chdir(::File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|sorbet)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = ['simple_feature_flags']
  spec.require_paths = ['lib']

  spec.add_dependency 'sorbet-runtime', '> 0.5'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
