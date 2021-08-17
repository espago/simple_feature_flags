# frozen_string_literal: true

module SimpleFeatureFlags
  class Configuration
    attr_accessor :default_id_method

    def initialize
      @default_id_method = :id
    end
  end
end
