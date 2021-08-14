module Support
  module UniversalStorageTests
    class TestObject
      alias id object_id
    end

    def test_correctly_import_flags_from_yaml
      assert @feature_flags.active?('feature_one')
      assert !@feature_flags.active?('feature_two')

      assert !@feature_flags.exists?('feature_remove')

      assert @feature_flags.exists?('feature_remain')

      number = 2
      @feature_flags.when_active('feature_one') do
        number += 1
      end
      assert_equal 3, number

      @feature_flags.when_active('feature_two') do
        number += 1
      end
      assert_equal 3, number

      assert_equal 3, number

      @feature_flags.when_active('feature_three', true) do
        number += 1
      end
      assert_equal 3, number
    end

    def test_add_a_new_feature
      assert_equal 3, @feature_flags.all.size

      assert @feature_flags.add('feature_three', 'Some new description')
      assert !@feature_flags.active?('feature_three', true)

      assert_equal 'Some new description', @feature_flags.description('feature_three')

      assert_equal 4, @feature_flags.all.size

      assert @feature_flags.add('feature_four', 'Some other new description', true)
      assert @feature_flags.active?('feature_four', true)

      assert_equal 'Some other new description', @feature_flags.description('feature_four')

      assert_equal 5, @feature_flags.all.size
    end

    def test_not_add_a_new_feature_when_it_exists
      assert_equal 3, @feature_flags.all.size

      assert !@feature_flags.add('feature_one', 'Some new description')
      assert @feature_flags.active?('feature_one')
      assert_equal 'Some description', @feature_flags.description('feature_one')

      assert_equal 3, @feature_flags.all.size
    end

    def test_remove_a_feature
      assert_equal 3, @feature_flags.all.size

      assert @feature_flags.remove(:feature_one)
      assert !@feature_flags.active?('feature_one')
      assert !@feature_flags.active?(:feature_one)
      assert !@feature_flags.exists?(:feature_one)
      assert !@feature_flags.exists?('feature_one')

      assert_equal 2, @feature_flags.all.size
    end

    def test_not_remove_a_feature_when_it_does_not_exist
      assert_equal 3, @feature_flags.all.size

      assert !@feature_flags.remove('feature_three')
      assert !@feature_flags.active?('feature_three', true)

      assert_equal 3, @feature_flags.all.size
    end

    def test_activate_a_feature
      assert_equal 3, @feature_flags.all.size

      @feature_flags.activate(:feature_two)
      assert @feature_flags.active?('feature_two')
      assert @feature_flags.active?(:feature_two)

      assert_equal 3, @feature_flags.all.size
    end

    def test_not_activate_a_feature_when_it_does_not_exist
      assert_equal 3, @feature_flags.all.size

      assert !@feature_flags.activate('feature_three')
      assert !@feature_flags.active?('feature_three', true)

      assert_equal 3, @feature_flags.all.size
    end

    def test_deactivate_a_feature
      assert_equal 3, @feature_flags.all.size

      assert @feature_flags.deactivate(:feature_one)
      assert !@feature_flags.active?('feature_one')

      assert_equal 3, @feature_flags.all.size
    end

    def test_not_deactivate_a_feature_when_it_does_not_exist
      assert_equal 3, @feature_flags.all.size

      assert !@feature_flags.deactivate('feature_three')
      assert !@feature_flags.active?('feature_three', true)

      assert_equal 3, @feature_flags.all.size
    end

    # FEATURE FLAGS PER MODEL

    def test_activate_an_active_flag_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new

      test_value = 1

      assert @feature_flags.active?(:feature_one)
      assert !@feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)

      @feature_flags.when_active_for(:feature_one, test_object) do
        test_value += 1
      end

      assert_equal 1, test_value

      assert @feature_flags.activate_for(:feature_one, test_object)

      assert @feature_flags.active?(:feature_one)
      assert @feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)

      @feature_flags.when_active_for(:feature_one, test_object) do
        test_value += 1
      end

      assert_equal 2, test_value
    end

    def test_not_activate_a_deactivated_flag_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new

      test_value = 1

      assert !@feature_flags.active?(:feature_two)
      assert !@feature_flags.active_for?(:feature_two, test_object)
      assert !@feature_flags.active_for?(:feature_two, test_object_two)

      @feature_flags.when_active_for(:feature_two, test_object) do
        test_value += 1
      end

      assert_equal 1, test_value

      assert @feature_flags.activate_for(:feature_two, test_object)
      assert !@feature_flags.active?(:feature_two)
      assert !@feature_flags.active_for?(:feature_two, test_object)
      assert !@feature_flags.active_for?(:feature_two, test_object_two)

      @feature_flags.when_active_for(:feature_two, test_object) do
        test_value += 1
      end

      assert_equal 1, test_value

      assert @feature_flags.activate(:feature_two)
      assert @feature_flags.active?(:feature_two)
      assert @feature_flags.active_for?(:feature_two, test_object)
      assert !@feature_flags.active_for?(:feature_two, test_object_two)

      @feature_flags.when_active_for(:feature_two, test_object) do
        test_value += 1
      end

      assert_equal 2, test_value
    end

    def test_activate_a_flag_globally
      test_object = TestObject.new
      test_object_two = TestObject.new

      assert !@feature_flags.active?(:feature_two)
      assert !@feature_flags.active_for?(:feature_two, test_object)
      assert !@feature_flags.active_for?(:feature_two, test_object_two)

      assert @feature_flags.activate!(:feature_two)

      assert @feature_flags.active?(:feature_two)
      assert @feature_flags.active_for?(:feature_two, test_object)
      assert @feature_flags.active_for?(:feature_two, test_object_two)
    end

    def test_activate_an_active_flag_for_model_with_custom_id_method
      test_object = ::Object.new
      test_object_two = ::Object.new

      assert !test_object.respond_to?(:id)

      assert @feature_flags.active?(:feature_one)
      assert !@feature_flags.active_for?(:feature_one, test_object, :object_id)
      assert !@feature_flags.active_for?(:feature_one, test_object_two, :object_id)

      assert @feature_flags.activate_for(:feature_one, test_object, :object_id)

      assert @feature_flags.active?(:feature_one)
      assert @feature_flags.active_for?(:feature_one, test_object, :object_id)
      assert !@feature_flags.active_for?(:feature_one, test_object_two, :object_id)
    end

    def test_activate_a_flag_for_multiple_models
      test_object = TestObject.new
      test_object_two = TestObject.new
      test_object_three = TestObject.new

      assert @feature_flags.active?(:feature_one)
      assert !@feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)
      assert !@feature_flags.active_for?(:feature_one, test_object_three)

      assert @feature_flags.activate_for(:feature_one, [test_object, test_object_two])
      assert @feature_flags.active_for?(:feature_one, test_object)
      assert @feature_flags.active_for?(:feature_one, test_object_two)
      assert !@feature_flags.active_for?(:feature_one, test_object_three)
    end

    def test_deactivate_a_flag_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new

      assert @feature_flags.activate_for(:feature_one, test_object)

      assert @feature_flags.active?(:feature_one)
      assert @feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)

      assert @feature_flags.deactivate_for(:feature_one, test_object)

      assert @feature_flags.active?(:feature_one)
      assert !@feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)
    end

    def test_deactivate_multiple_flags_for_a_model
      test_object = TestObject.new
      test_object_two = TestObject.new
      test_object_three = TestObject.new

      assert @feature_flags.activate_for(:feature_one, [test_object, test_object_two])

      assert @feature_flags.active?(:feature_one)
      assert @feature_flags.active_for?(:feature_one, test_object)
      assert @feature_flags.active_for?(:feature_one, test_object_two)
      assert !@feature_flags.active_for?(:feature_one, test_object_three)

      assert @feature_flags.deactivate_for(:feature_one, [test_object, test_object_two])

      assert @feature_flags.active?(:feature_one)
      assert !@feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)
      assert !@feature_flags.active_for?(:feature_one, test_object_three)
    end

    def test_deactivate_globally
      test_object = TestObject.new
      test_object_two = TestObject.new
      test_object_three = TestObject.new

      assert @feature_flags.activate_for(:feature_one, [test_object, test_object_two])

      assert @feature_flags.active?(:feature_one)
      assert @feature_flags.active_for?(:feature_one, test_object)
      assert @feature_flags.active_for?(:feature_one, test_object_two)
      assert !@feature_flags.active_for?(:feature_one, test_object_three)

      assert @feature_flags.deactivate(:feature_one)

      assert !@feature_flags.active?(:feature_one)
      assert !@feature_flags.active_for?(:feature_one, test_object)
      assert !@feature_flags.active_for?(:feature_one, test_object_two)
      assert !@feature_flags.active_for?(:feature_one, test_object_three)
    end
  end
end