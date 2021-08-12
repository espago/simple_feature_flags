# frozen_string_literal: true

module SimpleFeatureFlags
  class Error < StandardError; end
end

Dir[File.expand_path('simple_feature_flags/*', __dir__)].sort.each { |file| require file }
