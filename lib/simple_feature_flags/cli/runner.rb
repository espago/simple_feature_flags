# typed: true
# frozen_string_literal: true

module SimpleFeatureFlags
  module Cli
    # Runs CLI commands
    class Runner
      extend T::Sig

      sig { returns(Options) }
      attr_reader :options

      sig { params(args: T::Array[String]).void }
      def initialize(args = ARGV)
        @options = Options.new(args)
      end

      sig { void }
      def run
        command_class =
          if @options.generate
            ::SimpleFeatureFlags::Cli::Command::Generate
          else
            raise NoSuchCommandError, 'No such command!'
          end

        command_class.new(options).run
      end
    end
  end
end
