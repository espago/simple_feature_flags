# typed: true
# frozen_string_literal: true

require 'fileutils'

module SimpleFeatureFlags
  module Cli
    module Command
      # Implements the `generate` CLI command
      class Generate
        extend T::Sig

        CONFIG_FILE = 'simple_feature_flags.yml' #: String

        #: Options
        attr_reader :options

        #: (Options options) -> void
        def initialize(options)
          @options = options
        end

        #: -> void
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

        #: -> void
        def generate_for_rails
          ::FileUtils.cp_r example_config_dir, destination_dir

          puts 'Generated:'
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

        #: (String file_path, Regexp regexp) { (String arg0) -> String } -> void
        def file_gsub(file_path, regexp, &block)
          new_content = File.read(file_path).gsub(regexp, &block)
          File.binwrite(file_path, new_content)
        end

        #: (String file_path, String line) -> void
        def file_append(file_path, line)
          new_content = File.read(file_path)
          new_content = "#{new_content}\n#{line}\n"
          File.binwrite(file_path, new_content)
        end

        #: (String dir, ?Integer embed_level) -> void
        def print_dir_tree(dir, embed_level = 0)
          padding = ' ' * (embed_level * 2)

          children = ::Dir.new(dir).entries.grep_v(/^\.{1,2}$/)

          children.each do |child|
            child_dir = ::File.join(dir, child)
            ::Dir.new(::File.join(dir, child))
            puts "#{padding}- #{child}"
            print_dir_tree(child_dir, embed_level + 1)
          rescue Errno::ENOTDIR
            puts "#{padding}* #{child}"
          end
        end

        #: -> String
        def initializer_file
          ::File.join(destination_dir, 'config', 'initializers', 'simple_feature_flags.rb')
        end

        #: -> String
        def gemfile
          ::File.join(destination_dir, 'Gemfile')
        end

        #: -> String
        def routes_rb
          ::File.join(destination_dir, 'config', 'routes.rb')
        end

        #: -> String
        def example_config_dir
          ::File.join(::File.expand_path(__dir__), '..', '..', '..', 'example_files', 'config')
        end

        #: -> String
        def example_config_file
          ::File.join(example_config_dir, CONFIG_FILE)
        end

        #: -> String
        def destination_dir
          if options.rails && !::Dir.new(::Dir.pwd).entries.include?('config')
            raise IncorrectWorkingDirectoryError,
                  'You should enter the main directory of your Rails project!'
          end

          ::Dir.pwd
        end

        #: -> String
        def destination_file
          @destination_file ||= ::File.join(destination_dir, CONFIG_FILE)
        end
      end
    end
  end
end
