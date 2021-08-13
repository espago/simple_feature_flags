# frozen_string_literal: true

module SimpleFeatureFlags
  class NoSuchCommandError < StandardError; end

  class IncorrectWorkingDirectoryError < StandardError; end

  class FlagNotDefinedError < StandardError; end
end

Dir[File.expand_path('simple_feature_flags/*.rb', __dir__)].sort.each { |file| require file }
