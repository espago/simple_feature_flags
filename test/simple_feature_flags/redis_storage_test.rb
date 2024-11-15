# typed: true
# frozen_string_literal: true

require 'test_helper'
require 'support/universal_storage_tests'

require 'redis'
require 'redis-namespace'

module SimpleFeatureFlags
  class RedisStorageTest < Minitest::Test
    extend T::Sig

    def setup
      flags = {
        mandatory: [
          {
            'name'        => 'feature_one',
            'active'      => 'true',
            'description' => 'Some description mandatory',
          },
          {
            'name'        => 'feature_two',
            'description' => 'Some description 2',
          },
        ],
        remove:    %w[feature_remove],
      }
      empty_file = Tempfile.new("empty_feature_flags_#{Time.now.to_i}")
      file = Tempfile.new("feature_flags_#{Time.now.to_i}")
      File.write(T.must(file.path), T.unsafe(flags).to_yaml)

      redis = Redis.new(db: 14)
      redis_namespaced = Redis::Namespace.new(:feature_flags, redis: redis)

      # clean redis before each test
      init_feature_flags = SimpleFeatureFlags::RedisStorage.new(redis_namespaced, T.must(empty_file.path))
      T.must(init_feature_flags.namespaced_redis).redis.flushdb
      assert init_feature_flags.add('feature_remove', 'Remove description', true)
      assert init_feature_flags.add('feature_remain', 'Remain description', true)
      assert init_feature_flags.add('feature_one', 'Some description', true)

      @feature_flags = SimpleFeatureFlags::RedisStorage.new(redis_namespaced, T.must(file.path))
    end

    sig { override.returns(SimpleFeatureFlags::RedisStorage) }
    attr_reader :feature_flags

    include ::Support::UniversalStorageTests

    def test_should_not_throw_errors_on_non_mandatory_flags
      assert_equal SimpleFeatureFlags::RedisStorage, @feature_flags.class
      assert !feature_flags.redis.nil?
      assert feature_flags.active?('feature_one')
      assert !feature_flags.active?('feature_two')
      assert !feature_flags.active?('feature_three')
      assert !feature_flags.active?('feature_remove')
      assert !feature_flags.exists?('feature_remove')
      assert feature_flags.active?('feature_remain')
      assert feature_flags.exists?('feature_remain')

      number = 2
      feature_flags.when_active('feature_one') do
        number += 1
      end
      assert_equal 3, number

      feature_flags.when_active('feature_two') do
        number += 1
      end
      assert_equal 3, number

      feature_flags.when_active('feature_three') do
        number += 1
      end
      assert_equal 3, number

      feature_flags.when_active('feature_three') do
        number += 1
      end
      assert_equal 3, number
    end
  end
end
