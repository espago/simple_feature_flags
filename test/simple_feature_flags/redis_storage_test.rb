# frozen_string_literal: true

require 'test_helper'
require 'redis'
require 'redis-namespace'
require 'yaml'

module SimpleFeatureFlags
  class RedisStorageTest < Minitest::Test
    def setup
      flags = {
        mandatory: [
          {
            'name' => 'feature_one',
            'active' => 'true',
            'description' => 'Some description mandatory'
          },
          {
            'name' => 'feature_two',
            'description' => 'Some description 2'
          }
        ],
        remove: %w[feature_remove]
      }
      empty_file = Tempfile.new("empty_feature_flags_#{Time.now.to_i}")
      file = Tempfile.new("feature_flags_#{Time.now.to_i}")
      File.write(file.path, flags.to_yaml)

      redis = Redis.new(db: 14)
      redis_namespaced = Redis::Namespace.new(:feature_flags, redis: redis)

      # clean redis before each test
      init_feature_flags = SimpleFeatureFlags::RedisStorage.new(redis_namespaced, empty_file.path)
      init_feature_flags.namespaced_redis.redis.flushdb
      assert init_feature_flags.add('feature_remove', 'Remove description', true)
      assert init_feature_flags.add('feature_remain', 'Remain description', true)
      assert init_feature_flags.add('feature_one', 'Some description', true)
      init_feature_flags = nil

      @feature_flags = SimpleFeatureFlags::RedisStorage.new(redis_namespaced, file.path)
    end

    def test_should_not_throw_errors_on_non_mandatory_flags
      assert_equal SimpleFeatureFlags::RedisStorage, @feature_flags.class
      assert !@feature_flags.redis.nil?
      assert @feature_flags.active?('feature_one')
      assert !@feature_flags.active?('feature_two')
      assert !@feature_flags.active?('feature_three')
      assert !@feature_flags.active?('feature_remove')
      assert !@feature_flags.exists?('feature_remove')
      assert  @feature_flags.active?('feature_remain')
      assert @feature_flags.exists?('feature_remain')

      number = 2
      @feature_flags.with_feature('feature_one') do
        number += 1
      end
      assert_equal 3, number

      @feature_flags.with_feature('feature_two') do
        number += 1
      end
      assert_equal 3, number

      @feature_flags.with_feature('feature_three') do
        number += 1
      end
      assert_equal 3, number

      @feature_flags.with_feature('feature_three', true) do
        number += 1
      end
      assert_equal 3, number
    end

    def test_correctly_import_flags_from_yaml
      assert @feature_flags.active?('feature_one')
      assert !@feature_flags.active?('feature_two')

      assert !@feature_flags.exists?('feature_remove')

      assert @feature_flags.exists?('feature_remain')

      number = 2
      @feature_flags.with_feature('feature_one') do
        number += 1
      end
      assert_equal 3, number

      @feature_flags.with_feature('feature_two') do
        number += 1
      end
      assert_equal 3, number

      assert_equal 3, number

      @feature_flags.with_feature('feature_three', true) do
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
  end
end
