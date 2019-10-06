module Michi
  class Executor
    class Local
      attr_reader :service

      delegate :config, :command, to: :service

      def initialize(service)
        @service = service
      end

      def prepare
        # no-op
      end

      def cleanup
        # no-op
      end

      def commit(script_file)
        system(script_file)
      end
    end
  end
end
