# typed: true
# frozen_string_literal: true

module SimpleFeatureFlags
  # The main configuration object of the library.
  class Configuration
    extend T::Sig

    sig { returns(Symbol) }
    attr_accessor :default_id_method

    sig { void }
    def initialize
      @default_id_method = :id
    end
  end
end
