# frozen_string_literal: true

module SimpleFeatureFlags
  class TestRamStorage < RamStorage
    def active?(feature, ignore_file = false)
      raise(FlagNotDefinedError, "Feature Flag `#{feature}` is not defined as mandatory in #{file}") if !ignore_file && !mandatory_flags.include?(feature.to_s)

      __active__(feature)
    end
  end
end
