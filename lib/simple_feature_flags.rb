# typed: true
# frozen_string_literal: true

require 'json'
require 'sorbet-runtime'

Dir[File.expand_path('simple_feature_flags/*.rb', __dir__)].each { |file| require file }

# Tha main namespace of the `simple_feature_flags` gem.
module SimpleFeatureFlags
  NOT_PRESENT = ::Object.new.freeze
  UI_GEM = 'simple_feature_flags-ui'
  UI_CLASS_NAME = '::SimpleFeatureFlags::Ui'
  WEB_UI_CLASS_NAME = '::SimpleFeatureFlags::Ui::Web'

  ACTIVE_GLOBALLY = ::Set['globally', :globally, 'true', true].freeze #: Set[(String | Symbol | bool | NilClass)]
  ACTIVE_PARTIALLY = ::Set['partially', :partially].freeze #: Set[(String | Symbol | bool | NilClass)]

  class NoSuchCommandError < StandardError; end

  class IncorrectWorkingDirectoryError < StandardError; end

  class FlagNotDefinedError < StandardError; end

  CONFIG = Configuration.new #: Configuration

  class << self
    #: { (Configuration arg0) -> void } -> Configuration
    def configure(&block)
      block.call(CONFIG)
      CONFIG
    end
  end
end
