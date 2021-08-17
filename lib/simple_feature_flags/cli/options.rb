# frozen_string_literal: true

require 'optparse'

module SimpleFeatureFlags
  module Cli
    class Options
      attr_reader :opt_parser, :generate, :help, :rails, :ui

      def initialize(args)
        @rails = true
        @ui = false

        @opt_parser = ::OptionParser.new do |opts|
          opts.banner = 'Usage: simple_feature_flags [options]'

          opts.separator ''
          opts.separator 'Commands:'

          opts.on('-g', '--generate', 'Generate necessary config files') { @generate = true }

          opts.on('-h', '--help', 'Display the manual') do
            puts opts
            exit
          end

          opts.on('-v', '--version', 'Show gem version') do
            puts VERSION
            exit
          end

          opts.separator ''
          opts.separator 'Modifiers:'

          opts.on('--[no-]ui', '--[no-]web-ui', "Add the #{UI_GEM} gem and mount it in routes") { |u| @ui = u }
          opts.on('--[no-]rails', 'Use generators suited for Rails apps') { |r| @rails = r }
        end

        opt_parser.parse!(args)
      end
    end
  end
end
