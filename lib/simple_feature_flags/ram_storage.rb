# typed: true
# frozen_string_literal: true

require 'yaml'

module SimpleFeatureFlags
  # Stores feature flags in memory.
  class RamStorage < BaseStorage
    # @override
    #: String
    attr_reader :file

    # @override
    #: Array[String]
    attr_reader :mandatory_flags

    #: Hash[Symbol, Hash[String, Object]]
    attr_reader :flags

    #: (String file) -> void
    def initialize(file)
      @file = file
      @mandatory_flags = []
      @flags = {}

      import_flags_from_file
    end

    # Checks whether the flag is active. Returns `true`, `false`, `:globally` or `:partially`
    # @override
    #: ((Symbol | String) feature) -> (Symbol | bool)
    def active(feature)
      case flags.dig(feature.to_sym, 'active')
      when 'globally', :globally
        :globally
      when 'partially', :partially
        :partially
      when 'true', true
        true
      else
        false
      end
    end

    # Checks whether the flag is active.
    # @override
    #: ((Symbol | String) feature) -> bool
    def active?(feature)
      return true if active(feature)

      false
    end

    # Checks whether the flag is inactive.
    # @override
    #: ((Symbol | String) feature) -> bool
    def inactive?(feature)
      !active?(feature)
    end

    # Checks whether the flag is active globally, for every object.
    # @override
    #: ((Symbol | String) feature) -> bool
    def active_globally?(feature)
      ACTIVE_GLOBALLY.include? T.unsafe(flags.dig(feature.to_sym, 'active'))
    end

    # Checks whether the flag is inactive globally, for every object.
    # @override
    #: ((Symbol | String) feature) -> bool
    def inactive_globally?(feature)
      !active_globally?(feature)
    end

    # Checks whether the flag is active partially, only for certain objects.
    # @override
    #: ((Symbol | String) feature) -> bool
    def active_partially?(feature)
      ACTIVE_PARTIALLY.include? T.unsafe(flags.dig(feature.to_sym, 'active'))
    end

    # Checks whether the flag is inactive partially, only for certain objects.
    # @override
    #: ((Symbol | String) feature) -> bool
    def inactive_partially?(feature)
      !active_partially?(feature)
    end

    # Checks whether the flag is active for the given object.
    # @override
    #: ((Symbol | String) feature, Object object, ?object_id_method: Symbol) -> bool
    def active_for?(feature, object, object_id_method: CONFIG.default_id_method)
      return false unless active?(feature)
      return true if active_globally?(feature)

      active_objects_hash = active_objects(feature)
      active_ids = active_objects_hash[object.class.to_s]

      return false unless active_ids

      active_ids.include? object.public_send(object_id_method)
    end

    # Checks whether the flag is inactive for the given object.
    # @override
    #: ((Symbol | String) feature, Object object, ?object_id_method: Symbol) -> bool
    def inactive_for?(feature, object, object_id_method: CONFIG.default_id_method)
      !active_for?(feature, object, object_id_method: object_id_method)
    end

    # Checks whether the flag exists.
    # @override
    #: ((Symbol | String) feature) -> bool
    def exists?(feature)
      return false if [nil, ''].include? flags[feature.to_sym]

      true
    end

    # Returns the description of the flag if it exists.
    # @override
    #: ((Symbol | String) feature) -> String?
    def description(feature)
      flags.dig(feature.to_sym, 'description') #: as untyped
    end

    # Calls the given block if the flag is active.
    # @override
    #: ((Symbol | String) feature) { -> void } -> void
    def when_active(feature, &block)
      return unless active?(feature)

      block.call
    end

    # Calls the given block if the flag is inactive.
    # @override
    #: ((Symbol | String) feature) { -> void } -> void
    def when_inactive(feature, &block)
      return unless inactive?(feature)

      block.call
    end

    # Calls the given block if the flag is active globally.
    # @override
    #: ((Symbol | String) feature) { -> void } -> void
    def when_active_globally(feature, &block)
      return unless active_globally?(feature)

      block.call
    end

    # Calls the given block if the flag is inactive globally.
    # @override
    #: ((Symbol | String) feature) { -> void } -> void
    def when_inactive_globally(feature, &block)
      return unless inactive_globally?(feature)

      block.call
    end

    # Calls the given block if the flag is active partially.
    # @override
    #: ((Symbol | String) feature) { -> void } -> void
    def when_active_partially(feature, &block)
      return unless active_partially?(feature)

      block.call
    end

    # Calls the given block if the flag is inactive partially.
    # @override
    #: ((Symbol | String) feature) { -> void } -> void
    def when_inactive_partially(feature, &block)
      return unless inactive_partially?(feature)

      block.call
    end

    # Calls the given block if the flag is active for the given object.
    # @override
    #: ((Symbol | String) feature, Object object, ?object_id_method: Symbol) { -> void } -> void
    def when_active_for(feature, object, object_id_method: CONFIG.default_id_method, &block)
      return unless active_for?(feature, object, object_id_method: object_id_method)

      block.call
    end

    # Calls the given block if the flag is inactive for the given object.
    # @override
    #: ((Symbol | String) feature, Object object, ?object_id_method: Symbol) { -> void } -> void
    def when_inactive_for(feature, object, object_id_method: CONFIG.default_id_method, &block)
      return unless inactive_for?(feature, object, object_id_method: object_id_method)

      block.call
    end

    # Activates the given flag. Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature) -> bool
    def activate(feature)
      return false unless exists?(feature)

      flag = flags[feature.to_sym] #: as !nil
      flag['active'] = 'globally'

      true
    end

    alias activate_globally activate

    # @override
    #: [R] ((Symbol | String) feature) { -> R } -> R
    def do_activate(feature, &block)
      feature = feature.to_sym
      prev_value = flags.dig(feature, 'active')
      activate(feature)
      block.call
    ensure
      T.unsafe(flags)[feature]['active'] = prev_value
    end

    alias do_activate_globally do_activate

    # Activates the given flag partially. Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature) -> bool
    def activate_partially(feature)
      return false unless exists?(feature)

      flag = flags[feature.to_sym] #: as !nil
      flag['active'] = 'partially'

      true
    end

    # @override
    #: [R] ((Symbol | String) feature) { -> R } -> R
    def do_activate_partially(feature, &block)
      feature = feature.to_sym
      prev_value = flags.dig(feature, 'active')
      activate_partially(feature)
      block.call
    ensure
      T.unsafe(flags)[feature]['active'] = prev_value
    end

    # Activates the given flag for the given objects. Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature, *Object objects, ?object_id_method: Symbol) -> void
    def activate_for(feature, *objects, object_id_method: CONFIG.default_id_method)
      return false unless exists?(feature)

      to_activate_hash = objects_to_hash(objects, object_id_method: object_id_method)
      active_objects_hash = active_objects(feature)

      to_activate_hash.each do |klass, ids|
        (active_objects_hash[klass] = ids) && next unless active_objects_hash[klass]

        active_objects_hash[klass]&.concat(ids)&.uniq!&.sort! # rubocop:disable Style/SafeNavigationChainLength
      end

      flag = flags[feature.to_sym] #: as !nil
      flag['active_for_objects'] = active_objects_hash

      true
    end

    # Activates the given flag for the given objects and sets the flag as partially active.
    # Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature, *Object objects, ?object_id_method: Symbol) -> void
    def activate_for!(feature, *objects, object_id_method: CONFIG.default_id_method)
      return false unless T.unsafe(self).activate_for(feature, *objects, object_id_method: object_id_method)

      activate_partially(feature)
    end

    # Deactivates the given flag for all objects.
    # Resets the list of objects that this flag has been turned on for.
    # Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature) -> bool
    def deactivate!(feature)
      return false unless exists?(feature)

      flag = flags[feature.to_sym] #: as !nil
      flag['active'] = 'false'
      flag['active_for_objects'] = nil

      true
    end

    # Deactivates the given flag globally.
    # Does not reset the list of objects that this flag has been turned on for.
    # Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature) -> bool
    def deactivate(feature)
      return false unless exists?(feature)

      flag = flags[feature.to_sym] #: as !nil
      flag['active'] = 'false'

      true
    end

    # @override
    #: [R] ((Symbol | String) feature) { -> R } -> R
    def do_deactivate(feature, &block)
      feature = feature.to_sym
      prev_value = flags.dig(feature, 'active')
      deactivate(feature)
      block.call
    ensure
      T.unsafe(flags)[feature]['active'] = prev_value
    end

    # Returns a hash of Objects that the given flag is turned on for.
    # The keys are class/model names, values are arrays of IDs of instances/records.
    #
    # looks like this:
    #
    #      { "Page" => [25, 89], "Book" => [152] }
    #
    # @override
    #: ((Symbol | String) feature) -> Hash[String, Array[Object]]
    def active_objects(feature)
      T.unsafe(flags.dig(feature.to_sym, 'active_for_objects')) || {}
    end

    # Deactivates the given flag for the given objects. Returns `false` if it does not exist.
    # @override
    #: ((Symbol | String) feature, *Object objects, ?object_id_method: Symbol) -> void
    def deactivate_for(feature, *objects, object_id_method: CONFIG.default_id_method)
      return false unless exists?(feature)

      active_objects_hash = active_objects(feature)

      objects_to_deactivate_hash = objects_to_hash(objects, object_id_method: object_id_method)

      objects_to_deactivate_hash.each do |klass, ids_to_remove|
        active_ids = active_objects_hash[klass]
        next unless active_ids

        active_ids.reject! { |id| ids_to_remove.include? id }
      end

      flag = flags[feature.to_sym] #: as !nil
      flag['active_for_objects'] = active_objects_hash

      true
    end

    # Returns the data of the flag in a hash.
    # @override
    #: ((Symbol | String) feature) -> Hash[String, top]?
    def get(feature)
      return unless exists?(feature)

      flag = flags[feature.to_sym] #: as !nil
      flag['mandatory'] = mandatory_flags.include?(feature.to_s)

      flag
    end

    # Adds the given feature flag.
    # @override
    #: ((Symbol | String) feature, ?String description, ?(String | Symbol | bool)? active) -> Hash[String, top]?
    def add(feature, description = '', active = 'false')
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

      flags[feature.to_sym] = hash
    end

    # Removes the given feature flag.
    # Returns its data or nil if it does not exist.
    # @override
    #: ((Symbol | String) feature) -> Hash[String, top]?
    def remove(feature)
      return unless exists?(feature)

      removed = get(feature)
      flags.delete(feature.to_sym)

      removed
    end

    # Returns the data of all feature flags.
    # @override
    #: -> Array[Hash[String, top]]
    def all
      hashes = []

      flags.each_key do |key|
        hashes << get(key)
      end

      hashes
    end
  end
end
