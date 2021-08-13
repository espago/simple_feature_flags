# frozen_string_literal: true

require 'fileutils'
require 'byebug'

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
