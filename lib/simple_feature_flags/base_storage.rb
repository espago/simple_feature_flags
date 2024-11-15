# typed: true
# frozen_string_literal: true

require 'yaml'

module SimpleFeatureFlags
  # Abstract class for all storage adapters.
  class BaseStorage
    extend T::Sig
    extend T::Helpers

    abstract!

    # Path to the file with feature flags
    sig { abstract.returns(String) }
    def file; end

    sig { abstract.returns(T::Array[String]) }
    def mandatory_flags; end

    # Checks whether the flag is active. Returns `true`, `false`, `:globally` or `:partially`
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T.any(Symbol, T::Boolean)) }
    def active(feature); end

    # Checks whether the flag is active.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active?(feature); end

    # Checks whether the flag is inactive.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def inactive?(feature); end

    # Checks whether the flag is active globally, for every object.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active_globally?(feature); end

    # Checks whether the flag is inactive globally, for every object.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def inactive_globally?(feature); end

    # Checks whether the flag is active partially, only for certain objects.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def active_partially?(feature); end

    # Checks whether the flag is inactive partially, only for certain objects.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def inactive_partially?(feature); end

    # Checks whether the flag is active for the given object.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
        )
        .returns(T::Boolean)
    end
    def active_for?(feature, object, object_id_method: :id); end

    # Checks whether the flag is inactive for the given object.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
        )
        .returns(T::Boolean)
    end
    def inactive_for?(feature, object, object_id_method: :id); end

    # Checks whether the flag exists.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def exists?(feature); end

    # Returns the description of the flag if it exists.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T.nilable(String)) }
    def description(feature); end

    # Calls the given block if the flag is active.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_active(feature, &block); end

    # Calls the given block if the flag is inactive.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_inactive(feature, &block); end

    # Calls the given block if the flag is active globally.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_active_globally(feature, &block); end

    # Calls the given block if the flag is inactive globally.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_inactive_globally(feature, &block); end

    # Calls the given block if the flag is active partially.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_active_partially(feature, &block); end

    # Calls the given block if the flag is inactive partially.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
          block:   T.proc.void,
        ).void
    end
    def when_inactive_partially(feature, &block); end

    # Calls the given block if the flag is active for the given object.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
          block:            T.proc.void,
        ).void
    end
    def when_active_for(feature, object, object_id_method: CONFIG.default_id_method, &block); end

    # Calls the given block if the flag is inactive for the given object.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          object:           Object,
          object_id_method: Symbol,
          block:            T.proc.void,
        ).void
    end
    def when_inactive_for(feature, object, object_id_method: CONFIG.default_id_method, &block); end

    # Activates the given flag. Returns `false` if it does not exist.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def activate(feature); end

    # Activates the given flag globally. Returns `false` if it does not exist.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def activate_globally(feature); end

    # Activates the given flag partially. Returns `false` if it does not exist.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def activate_partially(feature); end

    # Activates the given flag for the given objects. Returns `false` if it does not exist.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          objects:          Object,
          object_id_method: Symbol,
        ).void
    end
    def activate_for(feature, *objects, object_id_method: CONFIG.default_id_method); end

    # Activates the given flag for the given objects and sets the flag as partially active.
    # Returns `false` if it does not exist.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          objects:          Object,
          object_id_method: Symbol,
        ).void
    end
    def activate_for!(feature, *objects, object_id_method: CONFIG.default_id_method); end

    # Deactivates the given flag for all objects.
    # Resets the list of objects that this flag has been turned on for.
    # Returns `false` if it does not exist.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def deactivate!(feature); end

    # Deactivates the given flag globally.
    # Does not reset the list of objects that this flag has been turned on for.
    # Returns `false` if it does not exist.
    sig { abstract.params(feature: T.any(Symbol, String)).returns(T::Boolean) }
    def deactivate(feature); end

    # Returns a hash of Objects that the given flag is turned on for.
    # The keys are class/model names, values are arrays of IDs of instances/records.
    #
    # looks like this:
    #
    #      { "Page" => [25, 89], "Book" => [152] }
    #
    sig do
      abstract
        .params(feature: T.any(Symbol, String))
        .returns(T::Hash[String, T::Array[Object]])
    end
    def active_objects(feature); end

    # Deactivates the given flag for the given objects. Returns `false` if it does not exist.
    sig do
      abstract
        .params(
          feature:          T.any(Symbol, String),
          objects:          Object,
          object_id_method: Symbol,
        ).void
    end
    def deactivate_for(feature, *objects, object_id_method: CONFIG.default_id_method); end

    # Returns the data of the flag in a hash.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
        ).returns(T.nilable(T::Hash[String, T.anything]))
    end
    def get(feature); end

    # Adds the given feature flag.
    sig do
      abstract
        .params(
          feature:     T.any(Symbol, String),
          description: String,
          active:      T.any(String, Symbol, T::Boolean, NilClass),
        ).returns(T.nilable(T::Hash[String, T.anything]))
    end
    def add(feature, description, active = 'false'); end

    # Removes the given feature flag.
    # Returns its data or nil if it does not exist.
    sig do
      abstract
        .params(
          feature: T.any(Symbol, String),
        ).returns(T.nilable(T::Hash[String, T.anything]))
    end
    def remove(feature); end

    # Returns the data of all feature flags.
    sig do
      abstract.returns(T::Array[T::Hash[String, T.anything]])
    end
    def all; end

    private

    sig { params(objects: T::Array[Object], object_id_method: Symbol).returns(T::Hash[String, T::Array[Object]]) }
    def objects_to_hash(objects, object_id_method: CONFIG.default_id_method)
      objects.group_by { |ob| ob.class.to_s }
             .transform_values { |arr| arr.map(&object_id_method) }
    end

    sig { void }
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
