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
#   active: 'globally' # %w[globally partially false] 'false' is the default value
#   description: example

- name: example_flag
  description: This is an example flag which will be automatically added when you start your app (it will be disabled)

- name: example_active_flag
  active: 'globally'
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

#### Activate a feature

Activates a feature in the global scope

```ruby
FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false

FEATURE_FLAGS.inactive?(:feature_name) #=> true
FEATURE_FLAGS.inactive_globally?(:feature_name) #=> true
FEATURE_FLAGS.inactive_partially?(:feature_name) #=> true

FEATURE_FLAGS.activate(:feature_name) # or FEATURE_FLAGS.activate_globally(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.active_globally?(:feature_name) #=> true
FEATURE_FLAGS.active_partially?(:feature_name) #=> false

FEATURE_FLAGS.inactive?(:feature_name) #=> false
FEATURE_FLAGS.inactive_globally?(:feature_name) #=> false
FEATURE_FLAGS.inactive_partially?(:feature_name) #=> true
```

#### Deactivate a feature

Deactivates a feature in the global scope

```ruby
FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.inactive?(:feature_name) #=> false

FEATURE_FLAGS.deactivate(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.inactive?(:feature_name) #=> true
```

#### Activate a feature for a particular record/object

```ruby
FEATURE_FLAGS.active_partially?(:feature_name) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

FEATURE_FLAGS.inactive_partially?(:feature_name) #=> false
FEATURE_FLAGS.inactive_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.inactive_for?(:feature_name, User.last) #=> true

FEATURE_FLAGS.activate_for(:feature_name, User.first) #=> true

FEATURE_FLAGS.active_partially?(:feature_name) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

FEATURE_FLAGS.inactive_partially?(:feature_name) #=> false
FEATURE_FLAGS.inactive_for?(:feature_name, User.first) #=> false
FEATURE_FLAGS.inactive_for?(:feature_name, User.last) #=> true
```

Note that the flag itself has to be active `partially` for any record/object specific settings to work.
When the flag is `deactivated` it is completely turned off globally and for every specific record/object.

```ruby
# The flag is deactivated in the global scope to begin with
FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

# We activate it for the first User
FEATURE_FLAGS.activate_for(:feature_name, User.first)

FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

# It is globally `deactivated` though, so the feature stays inactive for all users
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

# Once we activate the flag partially, record specific settings will be applied
FEATURE_FLAGS.activate_partially(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.active_partially?(:feature_name) #=> true
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

FEATURE_FLAGS.deactivate(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false
```

There is a convenience method `activate_for!`, which activates the feature partially and for specific records/objects at the same time

```ruby
# The flag is deactivated in the global scope to begin with
FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

# We activate it in the global scope and for the first User
FEATURE_FLAGS.activate_for!(:feature_name, User.first)

FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.active_partially?(:feature_name) #=> true
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false
```

You can also pass an array of objects to activate all of them simultaneously

```ruby
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.find(2)) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

FEATURE_FLAGS.activate_for(:feature_name, User.first(2))

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.find(2)) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false
```

#### Activate the feature for every record

```ruby
# The flag is active partially
FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.active_partially?(:feature_name) #=> true
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

# It is also enabled for the first user
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false

# We force it onto every user
FEATURE_FLAGS.activate(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> true

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> true

# We can easily return to the previous settings
FEATURE_FLAGS.activate_partially(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> true
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> true

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true
FEATURE_FLAGS.active_for?(:feature_name, User.last) #=> false
```

#### Deactivate a feature for a particular record/object

```ruby
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> true

FEATURE_FLAGS.deactivate_for(:feature_name, User.first)

FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false
```


#### Run a block of code only when the flag is active

There are two ways of running code only when the feature flag is active

```ruby
number = 1
if FEATURE_FLAGS.active?(:feature_name)
  number += 1
end

if FEATURE_FLAGS.inactive?(:feature_name)
  number += 1
end

# or using a block

# this code will run only when the :feature_name flag is active (either partially or globally)
FEATURE_FLAGS.when_active(:feature_name) do
  number += 1
end

# the opposite
FEATURE_FLAGS.when_inactive(:feature_name) do
  number += 1
end

# this code will run only when the :feature_name flag is active globally
FEATURE_FLAGS.when_active_globally(:feature_name) do
  number += 1
end

# the opposite
FEATURE_FLAGS.when_inactive_globally(:feature_name) do
  number += 1
end

# this code will run only when the :feature_name flag is active partially (only for specific records/users)
FEATURE_FLAGS.when_active_partially(:feature_name) do
  number += 1
end

# the opposite
FEATURE_FLAGS.when_inactive_partially(:feature_name) do
  number += 1
end

# this code will run only if the :feature_name flag is active for the first User
FEATURE_FLAGS.when_active_for(:feature_name, User.first) do
  number += 1
end

# the opposite
FEATURE_FLAGS.when_inactive_for(:feature_name, User.first) do
  number += 1
end

# feature flags that don't exist will return false
FEATURE_FLAGS.active?(:non_existant) #=> false
FEATURE_FLAGS.inactive?(:non_existant) #=> true

if FEATURE_FLAGS.active_for?(:feature_name, User.first)
  number += 1
end

if FEATURE_FLAGS.inactive_for?(:feature_name, User.first)
  number += 1
end
```

#### Adding feature flags

You can add new feature flags programmatically, though we highly encourage you to use the generated `config/simple_feature_flags.yml` file instead. It will make it easier to add and/or remove feature flags automatically on app startup without having to add them manually after merging a branch with new feature flags.

In case you'd like to add flags programmatically
```ruby
FEATURE_FLAGS.add(:feature_name, 'Description')

FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false
FEATURE_FLAGS.active_for?(:feature_name, User.first) #=> false

# add a new globally active flag
FEATURE_FLAGS.add(:active_feature, 'Description', :globally)

FEATURE_FLAGS.active?(:active_feature) #=> true
FEATURE_FLAGS.active_partially?(:active_feature) #=> false
FEATURE_FLAGS.active_globally?(:active_feature) #=> true
FEATURE_FLAGS.active_for?(:active_feature, User.first) #=> true

# add a new partially active flag
FEATURE_FLAGS.add(:feature_active_partially, 'Description', :partially)

FEATURE_FLAGS.active?(:feature_active_partially) #=> true
FEATURE_FLAGS.active_partially?(:feature_active_partially) #=> true
FEATURE_FLAGS.active_globally?(:feature_active_partially) #=> false
FEATURE_FLAGS.active_for?(:feature_active_partially, User.first) #=> false
```

#### Removing feature flags

You can remove feature flags programmatically, though we highly encourage you to use the generated `config/simple_feature_flags.yml` file instead. It will make it easier to add and/or remove feature flags automatically on app startup without having to add them manually after merging a branch with new feature flags.

In case you'd like to remove flags programmatically
```ruby
FEATURE_FLAGS.remove(:feature_name)

FEATURE_FLAGS.active?(:feature_name) #=> false
FEATURE_FLAGS.active_partially?(:feature_name) #=> false
FEATURE_FLAGS.active_globally?(:feature_name) #=> false

FEATURE_FLAGS.inactive?(:feature_name) #=> true
FEATURE_FLAGS.inactive_partially?(:feature_name) #=> true
FEATURE_FLAGS.inactive_globally?(:feature_name) #=> true
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/simple_feature_flags.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
