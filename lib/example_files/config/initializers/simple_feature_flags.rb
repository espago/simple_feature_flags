# frozen_string_literal: true
# Redis has 16 DBs (0 to 15)

FEATURE_FLAGS = if ::Rails.env.test?
                  # Use RamStorage in tests to make them faster
                  ::SimpleFeatureFlags::RamStorage.new("#{::Rails.root.to_s}/config/simple_feature_flags.yml")
                else
                  redis = ::Redis.new(host: '127.0.0.1', port: 6379, db: 0)
                  # We recommend using the `redis-namespace` gem to avoid key conflicts with Sidekiq or Resque
                  # redis = ::Redis::Namespace.new(:simple_feature_flags, redis: redis)

                  ::SimpleFeatureFlags::RedisStorage.new(redis, "#{::Rails.root.to_s}/config/simple_feature_flags.yml")
                end
