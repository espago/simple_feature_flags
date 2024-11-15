# typed: true
# frozen_string_literal: true

module SimpleFeatureFlags
  # Handles the CLI
  module Cli; end
end

Dir[File.expand_path('cli/*.rb', __dir__)].each { |file| require file }
