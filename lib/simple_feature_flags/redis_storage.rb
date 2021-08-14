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

    def active_globally?(feature)
      case redis.hget(feature.to_s, 'active')
      when 'globally'
        true
      else
        false
      end
    end

    def active_for?(feature, object, object_id_method = :id)
      return false unless active?(feature)
      return true if active_globally?(feature)

      active_objects_hash = active_objects(feature)
      active_ids = active_objects_hash[object.class.to_s]

      return false unless active_ids

      active_ids.include? object.public_send(object_id_method)
    end

    def exists?(feature)
      return false if [nil, ''].include? redis.hget(feature.to_s, 'name')

      true
    end

    def description(feature)
      redis.hget(feature.to_s, 'description')
    end

    def when_active(feature, _ignore_file = false, &block)
      return unless active?(feature)

      block.call
    end

    def when_active_for(feature, object, object_id_method = :id, &block)
      return unless active_for?(feature, object, object_id_method)

      block.call
    end

    def activate!(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'globally')

      true
    end

    alias activate_globally activate!

    def activate(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'true')

      true
    end

    def activate_for(feature, objects, object_id_method = :id)
      return false unless exists?(feature)

      objects = [objects] unless objects.is_a? ::Array
      to_activate_hash = objects_to_hash(objects, object_id_method)
      active_objects_hash = active_objects(feature)

      to_activate_hash.each do |klass, ids|
        (active_objects_hash[klass] = ids) && next unless active_objects_hash[klass]

        active_objects_hash[klass].concat(ids).sort!
      end

      redis.hset(feature.to_s, 'active_for_objects', active_objects_hash.to_json)

      true
    end

    def activate_for!(feature, objects, object_id_method = :id)
      return false unless activate_for(feature, objects, object_id_method)

      activate(feature)
    end

    def deactivate!(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'false')
      redis.hset(feature.to_s, 'active_for_objects', '')

      true
    end

    def deactivate(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'false')

      true
    end

    def active_objects(feature)
      ::JSON.parse(redis.hget(feature.to_s, 'active_for_objects').to_s)
    rescue ::JSON::ParserError
      {}
    end

    def deactivate_for(feature, objects, object_id_method = :id)
      return false unless exists?(feature)

      active_objects_hash = active_objects(feature)

      objects_to_deactivate_hash = objects_to_hash(objects, object_id_method)

      objects_to_deactivate_hash.each do |klass, ids_to_remove|
        active_ids = active_objects_hash[klass]
        next unless active_ids

        active_ids.reject! { |id| ids_to_remove.include? id }
      end

      redis.hset(feature.to_s, 'active_for_objects', active_objects_hash.to_json)

      true
    end

    def get(feature)
      return unless exists?(feature)

      hash = redis.hgetall(feature.to_s)
      hash['mandatory'] = mandatory_flags.include?(feature.to_s)
      hash['active_for_objects'] = ::JSON.parse(hash['active_for_objects']) rescue {}

      hash
    end

    def add(feature, description, active = 'false')
      return false if exists?(feature)

      active = case active
               when true, 'true'
                 'true'
               when 'globally', :globally
                 'globally'
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

    def objects_to_hash(objects, object_id_method = :id)
      objects = [objects] unless objects.is_a? ::Array

      objects.group_by { |ob| ob.class.to_s }.transform_values { |arr| arr.map(&object_id_method) }
    end

    def __active__(feature)
      case redis.hget(feature.to_s, 'active')
      when 'true', 'globally'
        true
      when 'false'
        false
      end
    end

    def import_flags_from_file
      changes = YAML.load_file(file)
      changes = { mandatory: [], remove: [] } unless changes.is_a? ::Hash

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
