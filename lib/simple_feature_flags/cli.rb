# frozen_string_literal: true

module SimpleFeatureFlags
  module Cli; end
end

Dir[File.expand_path('cli/*.rb', __dir__)].sort.each { |file| require file }
