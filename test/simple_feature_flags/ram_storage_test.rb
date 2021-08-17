# frozen_string_literal: true

require 'test_helper'
require 'support/universal_storage_tests'

module SimpleFeatureFlags
  class RamStorageTest < Minitest::Test
    def setup
      flags = {
        mandatory: [
          {
            'name' => 'feature_one',
            'active' => 'true',
            'description' => 'Some description'
          },
          {
            'name' => 'feature_two',
            'description' => 'Some description 2'
          }
        ],
        remove: %w[feature_remove]
      }
      file = Tempfile.new("feature_flags_#{Time.now.to_i}")
      File.write(file.path, flags.to_yaml)

      @feature_flags = SimpleFeatureFlags::RamStorage.new(file.path)
      assert @feature_flags.add('feature_remain', 'Remain description', true)
    end

    include ::Support::UniversalStorageTests

    def test_should_not_throw_errors_on_non_mandatory_flags
      assert_equal SimpleFeatureFlags::RamStorage, @feature_flags.class
      assert @feature_flags.redis.nil?
      assert @feature_flags.active?('feature_one')
      assert !@feature_flags.active?('feature_two')
      assert !@feature_flags.active?('feature_three')
      assert !@feature_flags.active?('feature_remove')
      assert !@feature_flags.exists?('feature_remove')
      assert  @feature_flags.active?('feature_remain')
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

      @feature_flags.when_active('feature_three') do
        number += 1
      end
      assert_equal 3, number

      @feature_flags.when_active('feature_three') do
        number += 1
      end
      assert_equal 3, number
    end
  end
end
