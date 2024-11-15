# typed: true
# frozen_string_literal: true

require 'test_helper'
require 'support/universal_storage_tests'

module SimpleFeatureFlags
  class TestRamStorageTest < Minitest::Test
    extend T::Sig

    def setup
      flags = {
        mandatory: [
          {
            'name'        => 'feature_one',
            'active'      => 'true',
            'description' => 'Some description',
          },
          {
            'name'        => 'feature_two',
            'description' => 'Some description 2',
          },
        ],
        remove:    %w[feature_remove],
      }
      file = Tempfile.new("feature_flags_#{Time.now.to_i}")
      File.write(T.must(file.path), T.unsafe(flags).to_yaml)

      @feature_flags = SimpleFeatureFlags::TestRamStorage.new(T.must(file.path))
      assert feature_flags.add('feature_remain', 'Remain description', true)
    end

    sig { returns(SimpleFeatureFlags::TestRamStorage) }
    attr_reader :feature_flags

    def test_correctly_throw_errors_on_non_mandatory_flags
      assert_equal SimpleFeatureFlags::TestRamStorage, feature_flags.class
      assert feature_flags.active?('feature_one')
      assert !feature_flags.active?('feature_two')

      assert_raises FlagNotDefinedError do
        feature_flags.active?('feature_three')
      end

      assert_raises FlagNotDefinedError do
        feature_flags.active?('feature_remove')
      end

      assert !feature_flags.exists?('feature_remove')

      assert_raises FlagNotDefinedError do
        feature_flags.active?('feature_remain')
      end

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

      assert_raises FlagNotDefinedError do
        feature_flags.when_active('feature_three') do
          number += 1
        end
      end

      assert_equal 3, number
    end
  end
end
