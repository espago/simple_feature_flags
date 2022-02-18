# frozen_string_literal: true

require 'json'

Dir[File.expand_path('simple_feature_flags/*.rb', __dir__)].sort.each { |file| require file }

module SimpleFeatureFlags
  NOT_PRESENT = ::Object.new.freeze
  UI_GEM = 'simple_feature_flags-ui'
  UI_CLASS_NAME = '::SimpleFeatureFlags::Ui'
  WEB_UI_CLASS_NAME = '::SimpleFeatureFlags::Ui::Web'

  ACTIVE_GLOBALLY = ::Set['globally', :globally, 'true', true].freeze
  ACTIVE_PARTIALLY = ::Set['partially', :partially].freeze

  class NoSuchCommandError < StandardError; end

  class IncorrectWorkingDirectoryError < StandardError; end

  class FlagNotDefinedError < StandardError; end

  CONFIG = Configuration.new

  def self.configure(&block)
    block.call(CONFIG)
  end
end
