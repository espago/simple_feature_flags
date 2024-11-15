# typed: true
# frozen_string_literal: true

require 'yaml'

module SimpleFeatureFlags
  # Stores feature flags in Redis.
  class RedisStorage < BaseStorage
    sig { override.returns(String) }
    attr_reader :file

    sig { override.returns(T::Array[String]) }
    attr_reader :mandatory_flags

    sig { returns(T.any(::Redis, ::Redis::Namespace)) }
    attr_reader :redis

    sig { params(redis: T.any(::Redis, ::Redis::Namespace), file: String).void }
    def initialize(redis, file)
      @file = file
      @redis = redis
      @mandatory_flags = []

      import_flags_from_file
    end

    # Checks whether the flag is active. Returns `true`, `false`, `:globally` or `:partially`
    sig { override.params(feature: T.any(Symbol, String)).returns(T.any(Symbol, T::Boolean)) }
    def active(feature)
      case redis.hget(feature.to_s, 'active')
      when 'globally'
        :globally
      when 'partially'
        :partially
      when 'true', true
        true
      else
        false
      end
    end

    # Checks whether the flag is active.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active?(feature)
      return true if active(feature)

      false
    end

    # Checks whether the flag is inactive.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def inactive?(feature)
      !active?(feature)
    end

    # Checks whether the flag is active globally, for every object.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active_globally?(feature)
      ACTIVE_GLOBALLY.include? redis.hget(feature.to_s, 'active')
    end

    # Checks whether the flag is inactive globally, for every object.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def inactive_globally?(feature)
      !active_globally?(feature)
    end

    # Checks whether the flag is active partially, only for certain objects.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active_partially?(feature)
      ACTIVE_PARTIALLY.include? redis.hget(feature.to_s, 'active')
    end

    # Checks whether the flag is inactive partially, only for certain objects.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def inactive_partially?(feature)
      !active_partially?(feature)
    end

    # Checks whether the flag is active for the given object.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
        )
        .returns(T::Boolean)
    end
    def active_for?(feature, object, object_id_method: CONFIG.default_id_method)
      return false unless active?(feature)
      return true if active_globally?(feature)

      active_objects_hash = active_objects(feature)
      active_ids = active_objects_hash[object.class.to_s]

      return false unless active_ids

      active_ids.include? object.public_send(object_id_method)
    end

    # Checks whether the flag is inactive for the given object.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
        )
        .returns(T::Boolean)
    end
    def inactive_for?(feature, object, object_id_method: CONFIG.default_id_method)
      !active_for?(feature, object, object_id_method: object_id_method)
    end

    # Checks whether the flag exists.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def exists?(feature)
      return false if [nil, ''].include? redis.hget(feature.to_s, 'name')

      true
    end

    # Returns the description of the flag if it exists.
    sig { override.params(feature: T.any(Symbol, String)).returns(T.nilable(String)) }
    def description(feature)
      redis.hget(feature.to_s, 'description')
    end

    # Calls the given block if the flag is active.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_active(feature, &block)
      return unless active?(feature)

      block.call
    end

    # Calls the given block if the flag is inactive.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_inactive(feature, &block)
      return unless inactive?(feature)

      block.call
    end

    # Calls the given block if the flag is active globally.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_active_globally(feature, &block)
      return unless active_globally?(feature)

      block.call
    end

    # Calls the given block if the flag is inactive globally.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_inactive_globally(feature, &block)
      return unless inactive_globally?(feature)

      block.call
    end

    # Calls the given block if the flag is active partially.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_active_partially(feature, &block)
      return unless active_partially?(feature)

      block.call
    end

    # Calls the given block if the flag is inactive partially.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_inactive_partially(feature, &block)
      return unless inactive_partially?(feature)

      block.call
    end

    # Calls the given block if the flag is active for the given object.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
          block:            T.proc.void,
        ).void
    end
    def when_active_for(feature, object, object_id_method: CONFIG.default_id_method, &block)
      return unless active_for?(feature, object, object_id_method: object_id_method)

      block.call
    end

    # Calls the given block if the flag is inactive for the given object.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
          block:            T.proc.void,
        ).void
    end
    def when_inactive_for(feature, object, object_id_method: CONFIG.default_id_method, &block)
      return unless inactive_for?(feature, object, object_id_method: object_id_method)

      block.call
    end

    # Activates the given flag. Returns `false` if it does not exist.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def activate(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'globally')

      true
    end

    alias activate_globally activate

    # Activates the given flag partially. Returns `false` if it does not exist.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def activate_partially(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'partially')

      true
    end

    # Activates the given flag for the given objects. Returns `false` if it does not exist.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          objects:          Object,
          object_id_method: Symbol,
        ).void
    end
    def activate_for(feature, *objects, object_id_method: CONFIG.default_id_method)
      return false unless exists?(feature)

      to_activate_hash = objects_to_hash(objects, object_id_method: object_id_method)
      active_objects_hash = active_objects(feature)

      to_activate_hash.each do |klass, ids|
        (active_objects_hash[klass] = ids) && next unless active_objects_hash[klass]

        active_objects_hash[klass]&.concat(ids)&.uniq!&.sort! # rubocop:disable Style/SafeNavigationChainLength
      end

      redis.hset(feature.to_s, 'active_for_objects', active_objects_hash.to_json)

      true
    end

    # Activates the given flag for the given objects and sets the flag as partially active.
    # Returns `false` if it does not exist.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          objects:          Object,
          object_id_method: Symbol,
        ).void
    end
    def activate_for!(feature, *objects, object_id_method: CONFIG.default_id_method)
      return false unless T.unsafe(self).activate_for(feature, *objects, object_id_method: object_id_method)

      activate_partially(feature)
    end

    # Deactivates the given flag for all objects.
    # Resets the list of objects that this flag has been turned on for.
    # Returns `false` if it does not exist.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def deactivate!(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'false')
      redis.hset(feature.to_s, 'active_for_objects', '')

      true
    end

    # Deactivates the given flag globally.
    # Does not reset the list of objects that this flag has been turned on for.
    # Returns `false` if it does not exist.
    sig { override.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def deactivate(feature)
      return false unless exists?(feature)

      redis.hset(feature.to_s, 'active', 'false')

      true
    end

    # Returns a hash of Objects that the given flag is turned on for.
    # The keys are class/model names, values are arrays of IDs of instances/records.
    #
    # looks like this:
    #
    #      { "Page" => [25, 89], "Book" => [152] }
    #
    sig do
      override
        .params(feature: T.any(Symbol, String))
        .returns(T::Hash[String, T::Array[Object]])
    end
    def active_objects(feature)
      ::JSON.parse(redis.hget(feature.to_s, 'active_for_objects').to_s)
    rescue ::JSON::ParserError
      {}
    end

    # Deactivates the given flag for the given objects. Returns `false` if it does not exist.
    sig do
      override
        .params(
          feature:          T.any(Symbol, String),
          objects:          Object,
          object_id_method: Symbol,
        ).void
    end
    def deactivate_for(feature, *objects, object_id_method: CONFIG.default_id_method)
      return false unless exists?(feature)

      active_objects_hash = active_objects(feature)

      objects_to_deactivate_hash = objects_to_hash(objects, object_id_method: object_id_method)

      objects_to_deactivate_hash.each do |klass, ids_to_remove|
        active_ids = active_objects_hash[klass]
        next unless active_ids

        active_ids.reject! { |id| ids_to_remove.include? id }
      end

      redis.hset(feature.to_s, 'active_for_objects', active_objects_hash.to_json)

      true
    end

    # Returns the data of the flag in a hash.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
        ).returns(T.nilable(T::Hash[String, T.anything]))
    end
    def get(feature)
      return unless exists?(feature)

      hash = redis.hgetall(feature.to_s)
      hash['mandatory'] = mandatory_flags.include?(feature.to_s)
      hash['active_for_objects'] = begin
        ::JSON.parse(hash['active_for_objects'])
      rescue StandardError
        {}
      end

      hash
    end

    # Adds the given feature flag.
    sig do
      override
        .params(
          feature:     T.any(Symbol, String),
          description: String,
          active:      T.any(String, Symbol, T::Boolean, NilClass),
        ).returns(T.nilable(T::Hash[String, T.anything]))
    end
    def add(feature, description, active = 'false')
      return if exists?(feature)

      active = if ACTIVE_GLOBALLY.include?(active)
                 'globally'
               elsif ACTIVE_PARTIALLY.include?(active)
                 'partially'
               else
                 'false'
               end

      hash = {
        'name'        => feature.to_s,
        'active'      => active,
        'description' => description,
      }

      redis.hset(feature.to_s, hash)
      hash
    end

    # Removes the given feature flag.
    # Returns its data or nil if it does not exist.
    sig do
      override
        .params(
          feature: T.any(Symbol, String),
        ).returns(T.nilable(T::Hash[String, T.anything]))
    end
    def remove(feature)
      return unless exists?(feature)

      removed = get(feature)
      redis.del(feature.to_s)

      removed
    end

    # Returns the data of all feature flags.
    sig do
      override.returns(T::Array[T::Hash[String, T.anything]])
    end
    def all
      keys = []
      hashes = []
      redis.scan_each(match: '*') do |key|
        next if keys.include?(key)

        keys << key
        hashes << get(key)
      end

      hashes
    end

    sig { returns(T.nilable(Redis::Namespace)) }
    def namespaced_redis
      r = redis
      return unless r.is_a?(Redis::Namespace)

      r
    end
  end
end
