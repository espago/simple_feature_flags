# Simple Feature Flags

Fast, simple and reliable feature flags using Redis or local memory in your Rails app.

## Table of Contents
[[_TOC_]]

## Installation

### Gem installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_feature_flags'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install simple_feature_flags

### Generate config files

This gem uses it's custom generator to make configuration easier for you.

#### Rails apps

1. Navigate to the root directory of your Rails project
1. Generate config files

   ```sh
    $ simple_feature_flags -g
    # or
    $ simple_feature_flags --generate
   ```

This should generate an initializer `config/initializers/simple_feature_flags.rb`

```ruby
# config/initializers/simple_feature_flags.rb

# frozen_string_literal: true
# Redis has 16 DBs (0 to 15)

FEATURE_FLAGS = if ::Rails.env.test?
                  # Use TestRamStorage in tests to make them faster
                  ::SimpleFeatureFlags::TestRamStorage.new("#{::Rails.root.to_s}/config/simple_feature_flags.yml")
                else
                  redis = ::Redis.new(host: '127.0.0.1', port: 6379, db: 0)
                  # We recommend using the `redis-namespace` gem to avoid key conflicts with Sidekiq or Resque
                  # redis = ::Redis::Namespace.new(:simple_feature_flags, redis: redis)

                  ::SimpleFeatureFlags::RedisStorage.new(redis, "#{::Rails.root.to_s}/config/simple_feature_flags.yml")
                end
```

This initializer in turn makes use of the generated config file `config/simple_feature_flags.yml`

```yaml
---
# Feature Flags that will be created if they don't exist already
:mandatory:
# example flag - it will be created with these properties if there is no such flag in Redis/RAM
# - name: example
#   active: 'true' # 'false' is the default value
#   description: example

- name: example_flag
  description: This is an example flag which will be automatically added when you start your app (it will be disabled)

- name: example_active_flag
  active: 'true'
  description: This is an example flag which will be automatically added when you start your app (it will be enabled)

# nothing will happen if flag that is to be removed does not exist in Redis/RAM
# An array of Feature Flag names that will be removed on app startup
:remove:
- flag_to_be_removed

```

#### Non-Rails apps

1. Navigate to the root directory of your project
1. Generate config files

   ```sh
    $ simple_feature_flags -g --no-rails
    # or
    $ simple_feature_flags --generate --no-rails
   ```

## Usage

This gem provides an easy way of dealing with feature flags. At this point in time it only supports global feature flags stored either in RAM or Redis.

### Storage types/Storage adapters

All storage adapters have the same API for dealing with feature flags. The only difference is in how they store data.

#### SimpleFeatureFlags::RedisStorage

This class makes use of Redis to store feature flag data. You can make use of it like so:

```ruby
require 'redis'

redis = ::Redis.new
config_file = "#{::Rails.root.to_s}/config/simple_feature_flags.yml"

FEATURE_FLAGS = ::SimpleFeatureFlags::RedisStorage.new(redis, config_file)
```

#### SimpleFeatureFlags::RamStorage

This class stores all feature flag data in a simple Ruby `::Hash`. You can make use of it like so:

```ruby
config_file = "#{::Rails.root.to_s}/config/simple_feature_flags.yml"

FEATURE_FLAGS = ::SimpleFeatureFlags::RamStorage.new(config_file)
```

### Functionality

#### Adding feature flags

You can add new feature flags programmatically, though we highly encourage you to use the generated `config/simple_feature_flags.yml` file instead. It will make it easier to add and/or remove feature flags automatically on app startup without having to add them manually after merging a branch with new feature flags.

In case you'd like to add flags programmatically
```ruby
FEATURE_FLAGS.add(:feature_name, 'Description')
FEATURE_FLAGS.active?(:feature_name) #=> false

# add a new active flag
FEATURE_FLAGS.add(:active_feature_name, 'Description', true)
FEATURE_FLAGS.active?(:active_feature_name) #=> true
```

#### Removing feature flags

You can remove feature flags programmatically, though we highly encourage you to use the generated `config/simple_feature_flags.yml` file instead. It will make it easier to add and/or remove feature flags automatically on app startup without having to add them manually after merging a branch with new feature flags.

In case you'd like to remove flags programmatically
```ruby
FEATURE_FLAGS.remove(:feature_name)
FEATURE_FLAGS.active?(:feature_name) #=> false
```

#### Run a block of code only when the flag is active

There are two ways of running code only when the feature flag is active

```ruby
number = 1
if FEATURE_FLAGS.active?(:feature_name)
    number += 1
end

# or using a block

# this code will run only when the :feature_name flag is active
FEATURE_FLAGS.with_feature(:feature_name) do
    number += 1
end

# feature flags that don't exist will return false
FEATURE_FLAGS.active?(:non_existant) #=> false
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/simple_feature_flags.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
