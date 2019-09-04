require "michi/version"
require "michi/config"

module Michi
  class Command
    class << self
      def execute
        puts "config: #{config}"
      end

      private

      def config
        @config ||= Config.new
      end
    end
  end
end
