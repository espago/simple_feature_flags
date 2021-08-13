# frozen_string_literal: true

module SimpleFeatureFlags
  module Cli
    module Command; end
  end
end

Dir[File.expand_path('command/*.rb', __dir__)].sort.each { |file| require file }
