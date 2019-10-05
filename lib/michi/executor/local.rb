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
        if command.tty?
          system(script_file)
        else
          system("#{script_file} >> #{service.log_path} 2>&1")
        end
      end
    end
  end
end
