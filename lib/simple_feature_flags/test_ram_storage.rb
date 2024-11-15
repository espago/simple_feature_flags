# typed: true
# frozen_string_literal: true

module SimpleFeatureFlags
  # Used in tests
  class TestRamStorage < RamStorage
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active?(feature)
      unless mandatory_flags.include?(feature.to_s)
        raise(FlagNotDefinedError,
              "Feature Flag `#{feature}` is not defined as mandatory in #{file}",)
      end

      super
    end
  end
end
