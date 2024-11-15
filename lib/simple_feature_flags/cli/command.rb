# typed: true
# frozen_string_literal: true

module SimpleFeatureFlags
  module Cli
    # Contains CLI commands
    module Command; end
  end
end

Dir[File.expand_path('command/*.rb', __dir__)].each { |file| require file }
