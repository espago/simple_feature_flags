# typed: true
# frozen_string_literal: true

module Support
  # @abstract
  module UniversalStorageTests
    class TestObject
      extend T::Sig

      #: -> Integer
      def id
        __id__
      end
    end

    extend T::Sig
    sig { abstract.params(val: T.anything).void }
    def assert(val); end
    sig { abstract.params(val1: T.anything, val2: T.anything).void }
    def assert_equal(val1, val2); end
    sig { abstract.returns(SimpleFeatureFlags::BaseStorage) }
    def feature_flags; end

    def test_correctly_import_flags_from_yaml
      assert feature_flags.active?('feature_one')
      assert !feature_flags.inactive?('feature_one')

      assert !feature_flags.active?('feature_two')
      assert feature_flags.inactive?('feature_two')

      assert !feature_flags.exists?('feature_remove')

      assert feature_flags.exists?('feature_remain')

      number = 2
      feature_flags.when_active('feature_one') do
        number += 1
      end
      assert_equal 3, number

      feature_flags.when_inactive('feature_one') do
        number += 1
      end
      assert_equal 3, number

      feature_flags.when_active('feature_two') do
        number += 1
      end
      assert_equal 3, number

      feature_flags.when_inactive('feature_two') do
        number += 1
      end
      assert_equal 4, number

      assert_equal 4, number

      feature_flags.when_active('feature_three') do
        number += 1
      end
      assert_equal 4, number

      feature_flags.when_inactive('feature_three') do
        number += 1
      end
      assert_equal 5, number
    end

    def test_do_deactivate
      assert_equal :globally, feature_flags.active('feature_one')
      feature_flags.do_deactivate('feature_one') do
        assert_equal false, feature_flags.active('feature_two')
      end
      assert_equal :globally, feature_flags.active('feature_one')

      feature_flags.add('feature_partial', '', :partially)
      assert_equal :partially, feature_flags.active('feature_partial')
      feature_flags.do_deactivate('feature_partial') do
        assert_equal false, feature_flags.active('feature_partial')
      end
      assert_equal :partially, feature_flags.active('feature_partial')
    end

    def test_do_activate
      assert_equal false, feature_flags.active('feature_two')
      feature_flags.do_activate('feature_two') do
        assert_equal :globally, feature_flags.active('feature_two')
      end
      assert_equal false, feature_flags.active('feature_two')

      feature_flags.add('feature_partial', '', :partially)
      assert_equal :partially, feature_flags.active('feature_partial')
      feature_flags.do_activate('feature_partial') do
        assert_equal :globally, feature_flags.active('feature_partial')
      end
      assert_equal :partially, feature_flags.active('feature_partial')
    end

    def test_do_activate_partially
      assert_equal false, feature_flags.active('feature_two')
      feature_flags.do_activate_partially('feature_two') do
        assert_equal :partially, feature_flags.active('feature_two')
      end
      assert_equal false, feature_flags.active('feature_two')

      feature_flags.add('feature_partial', '', true)
      assert_equal :globally, feature_flags.active('feature_partial')
      feature_flags.do_activate_partially('feature_partial') do
        assert_equal :partially, feature_flags.active('feature_partial')
      end
      assert_equal :globally, feature_flags.active('feature_partial')
    end

    def test_add_a_new_feature
      assert_equal 3, feature_flags.all.size

      assert feature_flags.add('feature_three', 'Some new description')
      assert !feature_flags.active?('feature_three')
      assert feature_flags.inactive?('feature_three')

      assert_equal 'Some new description', feature_flags.description('feature_three')

      assert_equal 4, feature_flags.all.size

      assert feature_flags.add('feature_four', 'Some other new description', true)
      assert feature_flags.active?('feature_four')
      assert !feature_flags.inactive?('feature_four')

      assert_equal 'Some other new description', feature_flags.description('feature_four')

      assert_equal 5, feature_flags.all.size
    end

    def test_not_add_a_new_feature_when_it_exists
      assert_equal 3, feature_flags.all.size

      assert !feature_flags.add('feature_one', 'Some new description')
      assert feature_flags.active?('feature_one')
      assert !feature_flags.inactive?('feature_one')
      assert_equal 'Some description', feature_flags.description('feature_one')

      assert_equal 3, feature_flags.all.size
    end

    def test_remove_a_feature
      assert_equal 3, feature_flags.all.size

      assert feature_flags.remove(:feature_one)
      assert !feature_flags.active?('feature_one')
      assert !feature_flags.active?(:feature_one)
      assert feature_flags.inactive?('feature_one')
      assert feature_flags.inactive?(:feature_one)
      assert !feature_flags.exists?(:feature_one)
      assert !feature_flags.exists?('feature_one')

      assert_equal 2, feature_flags.all.size
    end

    def test_not_remove_a_feature_when_it_does_not_exist
      assert_equal 3, feature_flags.all.size

      assert !feature_flags.remove('feature_three')
      assert !feature_flags.active?('feature_three')
      assert feature_flags.inactive?('feature_three')

      assert_equal 3, feature_flags.all.size
    end

    def test_activate_a_feature
      assert_equal 3, feature_flags.all.size

      feature_flags.activate(:feature_two)
      assert feature_flags.active?('feature_two')
      assert feature_flags.active?(:feature_two)
      assert !feature_flags.inactive?('feature_two')
      assert !feature_flags.inactive?(:feature_two)

      assert_equal 3, feature_flags.all.size
    end

    def test_not_activate_a_feature_when_it_does_not_exist
      assert_equal 3, feature_flags.all.size

      assert !feature_flags.activate('feature_three')
      assert !feature_flags.active?('feature_three')
      assert feature_flags.inactive?('feature_three')

      assert_equal 3, feature_flags.all.size
    end

    def test_deactivate_a_feature
      assert_equal 3, feature_flags.all.size

      assert feature_flags.deactivate(:feature_one)
      assert !feature_flags.active?('feature_one')
      assert feature_flags.inactive?('feature_one')

      assert_equal 3, feature_flags.all.size
    end

    def test_not_deactivate_a_feature_when_it_does_not_exist
      assert_equal 3, feature_flags.all.size

      assert !feature_flags.deactivate('feature_three')
      assert !feature_flags.active?('feature_three')
      assert feature_flags.inactive?('feature_three')

      assert_equal 3, feature_flags.all.size
    end

    # FEATURE FLAGS PER MODEL

    def test_activate_an_active_flag_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new

      test_value = 1

      assert feature_flags.activate_partially(:feature_one)

      assert feature_flags.active?(:feature_one)
      assert !feature_flags.inactive?(:feature_one)

      assert !feature_flags.active_globally?(:feature_one)
      assert feature_flags.inactive_globally?(:feature_one)
      assert feature_flags.active_partially?(:feature_one)
      assert !feature_flags.inactive_partially?(:feature_one)

      assert !feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)

      feature_flags.when_active_for(:feature_one, test_object) do
        test_value += 1
      end
      assert_equal 1, test_value

      feature_flags.when_inactive_for(:feature_one, test_object) do
        test_value += 1
      end
      assert_equal 2, test_value

      assert feature_flags.activate_for(:feature_one, test_object)

      assert feature_flags.active?(:feature_one)
      assert !feature_flags.inactive?(:feature_one)

      assert !feature_flags.active_globally?(:feature_one)
      assert feature_flags.active_partially?(:feature_one)
      assert feature_flags.inactive_globally?(:feature_one)
      assert !feature_flags.inactive_partially?(:feature_one)

      assert feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)

      feature_flags.when_active_for(:feature_one, test_object) do
        test_value += 1
      end
      assert_equal 3, test_value

      feature_flags.when_inactive_for(:feature_one, test_object) do
        test_value += 1
      end
      assert_equal 3, test_value
    end

    def test_not_activate_a_deactivated_flag_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new

      test_value = 1

      assert !feature_flags.active?(:feature_two)
      assert feature_flags.inactive?(:feature_two)

      assert !feature_flags.active_for?(:feature_two, test_object)
      assert !feature_flags.active_for?(:feature_two, test_object_two)
      assert feature_flags.inactive_for?(:feature_two, test_object)
      assert feature_flags.inactive_for?(:feature_two, test_object_two)

      feature_flags.when_active_for(:feature_two, test_object) do
        test_value += 1
      end
      assert_equal 1, test_value

      feature_flags.when_inactive_for(:feature_two, test_object) do
        test_value += 1
      end
      assert_equal 2, test_value

      assert feature_flags.activate_for(:feature_two, test_object)
      assert !feature_flags.active?(:feature_two)
      assert !feature_flags.active_for?(:feature_two, test_object)
      assert !feature_flags.active_for?(:feature_two, test_object_two)

      feature_flags.when_active_for(:feature_two, test_object) do
        test_value += 1
      end
      assert_equal 2, test_value

      feature_flags.when_inactive_for(:feature_two, test_object) do
        test_value += 1
      end
      assert_equal 3, test_value

      assert feature_flags.activate_partially(:feature_two)
      assert feature_flags.active?(:feature_two)
      assert feature_flags.active_partially?(:feature_two)
      assert !feature_flags.active_globally?(:feature_two)
      assert feature_flags.active_for?(:feature_two, test_object)
      assert !feature_flags.active_for?(:feature_two, test_object_two)

      feature_flags.when_active_for(:feature_two, test_object) do
        test_value += 1
      end
      assert_equal 4, test_value

      feature_flags.when_inactive_for(:feature_two, test_object) do
        test_value += 1
      end
      assert_equal 4, test_value

      feature_flags.when_active_partially(:feature_two) do
        test_value += 1
      end
      assert_equal 5, test_value

      feature_flags.when_inactive_partially(:feature_two) do
        test_value += 1
      end
      assert_equal 5, test_value
    end

    def test_activate_a_flag_globally
      test_object = TestObject.new
      test_object_two = TestObject.new

      assert !feature_flags.active?(:feature_two)
      assert !feature_flags.active_for?(:feature_two, test_object)
      assert !feature_flags.active_for?(:feature_two, test_object_two)

      assert feature_flags.inactive?(:feature_two)
      assert feature_flags.inactive_for?(:feature_two, test_object)
      assert feature_flags.inactive_for?(:feature_two, test_object_two)

      assert feature_flags.activate(:feature_two)

      assert feature_flags.active?(:feature_two)
      assert feature_flags.active_globally?(:feature_two)
      assert !feature_flags.active_partially?(:feature_two)
      assert feature_flags.active_for?(:feature_two, test_object)
      assert feature_flags.active_for?(:feature_two, test_object_two)

      assert !feature_flags.inactive?(:feature_two)
      assert !feature_flags.inactive_globally?(:feature_two)
      assert feature_flags.inactive_partially?(:feature_two)
      assert !feature_flags.inactive_for?(:feature_two, test_object)
      assert !feature_flags.inactive_for?(:feature_two, test_object_two)
    end

    def test_activate_an_active_flag_for_model_with_custom_id_method
      test_object = ::Object.new
      test_object_two = ::Object.new

      assert !test_object.respond_to?(:id)
      assert feature_flags.activate_partially(:feature_one)

      assert feature_flags.active?(:feature_one)
      assert feature_flags.active_partially?(:feature_one)
      assert !feature_flags.active_for?(:feature_one, test_object, object_id_method: :object_id)
      assert !feature_flags.active_for?(:feature_one, test_object_two, object_id_method: :object_id)

      assert !feature_flags.inactive?(:feature_one)
      assert !feature_flags.inactive_partially?(:feature_one)
      assert feature_flags.inactive_for?(:feature_one, test_object, object_id_method: :object_id)
      assert feature_flags.inactive_for?(:feature_one, test_object_two, object_id_method: :object_id)

      assert feature_flags.activate_for(:feature_one, test_object, object_id_method: :object_id)

      assert feature_flags.active?(:feature_one)
      assert feature_flags.active_for?(:feature_one, test_object, object_id_method: :object_id)
      assert !feature_flags.active_for?(:feature_one, test_object_two, object_id_method: :object_id)

      assert !feature_flags.inactive?(:feature_one)
      assert !feature_flags.inactive_for?(:feature_one, test_object, object_id_method: :object_id)
      assert feature_flags.inactive_for?(:feature_one, test_object_two, object_id_method: :object_id)
    end

    def test_activate_a_flag_for_multiple_models
      test_object = TestObject.new
      test_object_two = TestObject.new
      test_object_three = TestObject.new

      assert feature_flags.activate_partially(:feature_one)

      assert feature_flags.active?(:feature_one)
      assert !feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.active_for?(:feature_one, test_object_three)

      assert feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object_three)

      assert feature_flags.activate_for(:feature_one, test_object, test_object_two)

      assert feature_flags.active_for?(:feature_one, test_object)
      assert feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.active_for?(:feature_one, test_object_three)

      assert !feature_flags.inactive_for?(:feature_one, test_object)
      assert !feature_flags.inactive_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object_three)
    end

    def test_deactivate_a_flag_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new

      assert feature_flags.activate_partially(:feature_one)

      assert feature_flags.activate_for(:feature_one, test_object)

      assert feature_flags.active?(:feature_one)
      assert feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)

      assert !feature_flags.inactive?(:feature_one)
      assert !feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)

      assert feature_flags.deactivate_for(:feature_one, test_object)

      assert feature_flags.active?(:feature_one)
      assert !feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)

      assert !feature_flags.inactive?(:feature_one)
      assert feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)
    end

    def test_deactivate_a_flag_for_multiple_models
      test_object = TestObject.new
      test_object_two = TestObject.new
      test_object_three = TestObject.new

      assert feature_flags.activate_partially(:feature_one)

      assert feature_flags.activate_for(:feature_one, test_object, test_object_two)

      assert feature_flags.active?(:feature_one)
      assert feature_flags.active_for?(:feature_one, test_object)
      assert feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.active_for?(:feature_one, test_object_three)

      assert !feature_flags.inactive?(:feature_one)
      assert !feature_flags.inactive_for?(:feature_one, test_object)
      assert !feature_flags.inactive_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object_three)

      assert feature_flags.deactivate_for(:feature_one, test_object, test_object_two)

      assert feature_flags.active?(:feature_one)
      assert !feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.active_for?(:feature_one, test_object_three)

      assert !feature_flags.inactive?(:feature_one)
      assert feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object_three)
    end

    def test_deactivate_globally
      test_object = TestObject.new
      test_object_two = TestObject.new
      test_object_three = TestObject.new

      assert feature_flags.activate_partially(:feature_one)

      assert feature_flags.activate_for(:feature_one, test_object, test_object_two)

      assert feature_flags.active?(:feature_one)
      assert feature_flags.active_partially?(:feature_one)
      assert !feature_flags.active_globally?(:feature_one)
      assert feature_flags.active_for?(:feature_one, test_object)
      assert feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.active_for?(:feature_one, test_object_three)

      assert !feature_flags.inactive?(:feature_one)
      assert !feature_flags.inactive_partially?(:feature_one)
      assert feature_flags.inactive_globally?(:feature_one)
      assert !feature_flags.inactive_for?(:feature_one, test_object)
      assert !feature_flags.inactive_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object_three)

      assert feature_flags.deactivate(:feature_one)

      assert !feature_flags.active?(:feature_one)
      assert !feature_flags.active_partially?(:feature_one)
      assert !feature_flags.active_globally?(:feature_one)
      assert !feature_flags.active_for?(:feature_one, test_object)
      assert !feature_flags.active_for?(:feature_one, test_object_two)
      assert !feature_flags.active_for?(:feature_one, test_object_three)

      assert feature_flags.inactive?(:feature_one)
      assert feature_flags.inactive_partially?(:feature_one)
      assert feature_flags.inactive_globally?(:feature_one)
      assert feature_flags.inactive_for?(:feature_one, test_object)
      assert feature_flags.inactive_for?(:feature_one, test_object_two)
      assert feature_flags.inactive_for?(:feature_one, test_object_three)
    end
  end
end
