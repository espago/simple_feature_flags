# typed: true
# frozen_string_literal: true

require 'json'
require 'sorbet-runtime'

Dir[File.expand_path('simple_feature_flags/*.rb', __dir__)].each { |file| require file }

# Tha main namespace of the `simple_feature_flags` gem.
module SimpleFeatureFlags
  extend T::Sig

  NOT_PRESENT = ::Object.new.freeze
  UI_GEM = 'simple_feature_flags-ui'
  UI_CLASS_NAME = '::SimpleFeatureFlags::Ui'
  WEB_UI_CLASS_NAME = '::SimpleFeatureFlags::Ui::Web'

  ACTIVE_GLOBALLY = T.let(
    ::Set['globally', :globally, 'true', true].freeze,
    T::Set[T.any(String, Symbol, T::Boolean, NilClass)],
  )
  ACTIVE_PARTIALLY = T.let(
    ::Set['partially', :partially].freeze,
    T::Set[T.any(String, Symbol, T::Boolean, NilClass)],
  )

  class NoSuchCommandError < StandardError; end

  class IncorrectWorkingDirectoryError < StandardError; end

  class FlagNotDefinedError < StandardError; end

  CONFIG = T.let(Configuration.new, Configuration)

  class << self
    extend T::Sig

    sig { params(block: T.proc.params(arg0: Configuration).void).returns(Configuration) }
    def configure(&block)
      block.call(CONFIG)
      CONFIG
    end
  end
end
