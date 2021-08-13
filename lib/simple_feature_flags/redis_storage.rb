# frozen_string_literal: true

module SimpleFeatureFlags
  class RedisStorage
    attr_reader :file, :redis, :mandatory_flags

    def initialize(redis, file)
      @file = file
      @redis = redis
      @mandatory_flags = []

      import_flags_from_file
    end

    def active?(feature, _ignore_file = false)
      __active__(feature)
    end

    def exists?(feature)
      return false if [nil, ''].include? redis.hget(feature.to_s, 'name')

      true
    end

    def description(feature)
      redis.hget(feature.to_s, 'description')
    end

    def with_feature(feature, _ignore_file = false, &block)
      return unless active?(feature)

      block.call
    end

    def activate(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'true')

      true
    end

    def deactivate(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'false')

      true
    end

    def get(feature)
      return unless exists?(feature)

      hash = redis.hgetall(feature.to_s)
      hash['mandatory'] = mandatory_flags.include?(feature.to_s)

      hash
    end

    def add(feature, description, active = 'false')
      return false if exists?(feature)

      active = case active
               when true, 'true'
                 'true'
               else
                 'false'
               end

      hash = {
        'name' => feature.to_s,
        'active' => active,
        'description' => description
      }

      redis.hset(feature.to_s, hash)
      hash
    end

    def remove(feature)
      return false unless exists?(feature)

      removed = get(feature)
      redis.del(feature.to_s)

      removed
    end

    def all
      keys = []
      hashes = []
      redis.scan_each(match: "*") do |key|
        next if keys.include?(key)

        keys << key
        hashes << get(key)
      end

      hashes
    end

    def namespaced_redis
      redis
    end

    private

    def __active__(feature)
      case redis.hget(feature.to_s, 'active')
      when 'true'
        true
      when 'false'
        false
      end
    end

    def import_flags_from_file
      changes = YAML.load_file(file)
      changes = { mandatory: [], remove: [] } unless changes.is_a? Hash

      changes[:mandatory].each do |el|
        mandatory_flags << el['name']
        add(el['name'], el['description'], el['active'])
      end

      changes[:remove].each do |el|
        remove(el)
      end
    end
  end
end
