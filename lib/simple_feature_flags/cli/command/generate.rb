# frozen_string_literal: true

require 'fileutils'

module SimpleFeatureFlags
  module Cli
    module Command
      class Generate
        CONFIG_FILE = 'simple_feature_flags.yml'

        attr_reader :options

        def initialize(options)
          @options = options
        end

        def run
          if options.rails
            generate_for_rails
            return
          end

          ::FileUtils.cp example_config_file, destination_file

          puts 'Generated:'
          puts '----------'
          puts "* #{destination_file}"
        end

        private

        def generate_for_rails
          ::FileUtils.cp_r example_config_dir, destination_dir

          puts "Generated:"
          puts '----------'
          puts "- #{::File.join(destination_dir, 'config')}"
          print_dir_tree(example_config_dir, 1)

          return unless options.ui

          file_gsub(routes_rb, /.routes.draw do/) do |match|
            "#{match}\n  mount #{WEB_UI_CLASS_NAME}.new => '/admin/simple_feature_flags'\n"
          end

          ui_config_line = <<~CONF
            #{UI_CLASS_NAME}.configure do |config|
              config.instance = FEATURE_FLAGS
              config.featurable_class_names = %w[User]
            end
          CONF

          file_append(initializer_file, ui_config_line)
          file_append(gemfile, %(gem '#{UI_GEM}'))

          puts "\nModified:"
          puts '----------'
          puts "* #{routes_rb}"
          puts "* #{gemfile}"

          puts "\nBundling..."
          system 'bundle'
        end

        def file_gsub(file_path, regexp, &block)
          new_content = File.read(file_path).gsub(regexp, &block)
          File.open(file_path, 'wb') { |file| file.write(new_content) }
        end

        def file_append(file_path, line)
          new_content = File.read(file_path)
          new_content = "#{new_content}\n#{line}\n"
          File.open(file_path, 'wb') { |file| file.write(new_content) }
        end

        def print_dir_tree(dir, embed_level = 0)
          padding = ' ' * (embed_level * 2)

          children = ::Dir.new(dir).entries.reject { |el| /^\.{1,2}$/ =~ el }

          children.each do |child|
            child_dir = ::File.join(dir, child)
            ::Dir.new(::File.join(dir, child))
            puts "#{padding}- #{child}"
            print_dir_tree(child_dir, embed_level + 1)
          rescue Errno::ENOTDIR
            puts "#{padding}* #{child}"
          end
        end

        def initializer_file
          ::File.join(destination_dir, 'config', 'initializers', 'simple_feature_flags.rb')
        end

        def gemfile
          ::File.join(destination_dir, 'Gemfile')
        end

        def routes_rb
          ::File.join(destination_dir, 'config', 'routes.rb')
        end

        def example_config_dir
          ::File.join(::File.expand_path(__dir__), '..', '..', '..', 'example_files', 'config')
        end

        def example_config_file
          ::File.join(example_config_dir, CONFIG_FILE)
        end

        def destination_dir
          raise IncorrectWorkingDirectoryError, "You should enter the main directory of your Rails project!" if options.rails && !::Dir.new(::Dir.pwd).entries.include?('config')

          ::Dir.pwd
        end

        def destination_file
          @destination_file ||= ::File.join(destination_dir, CONFIG_FILE)
        end
      end
    end
  end
end
