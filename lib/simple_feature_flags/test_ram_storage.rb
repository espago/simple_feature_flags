# frozen_string_literal: true

module SimpleFeatureFlags
  class TestRamStorage < RamStorage
    def active?(feature)
      raise(FlagNotDefinedError, "Feature Flag `#{feature}` is not defined as mandatory in #{file}") unless mandatory_flags.include?(feature.to_s)

      super
    end
  end
end
