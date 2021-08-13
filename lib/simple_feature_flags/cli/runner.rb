# frozen_string_literal: true

module SimpleFeatureFlags
  module Cli
    class Runner
      attr_reader :options

      def initialize(args = ARGV)
        @options = Options.new(args)
      end

      def run
        command_class = if @options.generate
                          ::SimpleFeatureFlags::Cli::Command::Generate
                        else
                          raise NoSuchCommandError, 'No such command!'
                        end

        command_class.new(options).run
      end
    end
  end
end
