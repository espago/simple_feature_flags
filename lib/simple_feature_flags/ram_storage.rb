# frozen_string_literal: true

module SimpleFeatureFlags
  class RamStorage
    attr_reader :file, :mandatory_flags, :flags

    def initialize(file)
      @file = file
      @redis = redis
      @mandatory_flags = []
      @flags = {}

      import_flags_from_file
    end

    def active?(feature, _ignore_file = false)
      __active__(feature)
    end

    def active_globally?(feature)
      flags.dig(feature.to_sym, 'active') == 'globally'
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
      return false if [nil, ''].include? flags[feature.to_sym]

      true
    end

    def description(feature)
      flags.dig(feature.to_sym, 'description')
    end

    def when_active(feature, ignore_file = false, &block)
      return unless active?(feature, ignore_file)

      block.call
    end

    def when_active_for(feature, object, object_id_method = :id, &block)
      return unless active_for?(feature, object, object_id_method)

      block.call
    end

    def activate!(feature)
      return false unless exists?(feature)

      flags[feature.to_sym]['active'] = 'globally'

      true
    end

    def activate(feature)
      return false unless exists?(feature)

      flags[feature.to_sym]['active'] = 'true'

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

      flags[feature.to_sym]['active_for_objects'] = active_objects_hash

      true
    end

    def activate_for!(feature, objects, object_id_method = :id)
      return false unless activate_for(feature, objects, object_id_method)

      activate(feature)
    end

    def deactivate!(feature)
      return false unless exists?(feature)

      flags[feature.to_sym]['active'] = 'false'
      flags[feature.to_sym]['active_for_objects'] = nil

      true
    end

    def deactivate(feature)
      return false unless exists?(feature)

      flags[feature.to_sym]['active'] = 'false'

      true
    end

    def active_objects(feature)
      flags.dig(feature.to_sym, 'active_for_objects') || {}
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

      flags[feature.to_sym]['active_for_objects'] = active_objects_hash

      true
    end

    def get(feature)
      return unless exists?(feature)

      hash = flags[feature.to_sym]
      hash['mandatory'] = mandatory_flags.include?(feature.to_s)

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

      flags[feature.to_sym] = hash
    end

    def remove(feature)
      return false unless exists?(feature)

      removed = get(feature)
      flags.delete(feature.to_sym)

      removed
    end

    def all
      hashes = []

      flags.each do |key, _val|
        hashes << get(key)
      end

      hashes
    end

    def redis; end

    def namespaced_redis; end

    private

    def objects_to_hash(objects, object_id_method = :id)
      objects = [objects] unless objects.is_a? ::Array

      objects.group_by { |ob| ob.class.to_s }.transform_values { |arr| arr.map(&object_id_method) }
    end

    def __active__(feature)
      %w[true globally].include? flags.dig(feature.to_sym, 'active')
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
