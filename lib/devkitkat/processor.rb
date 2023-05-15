require 'parallel'

module Devkitkat
  class Processor
    attr_reader :services, :config, :command

    def initialize(services, command, config)
      @services = services
      @command = command
      @config = config
    end

    def execute
      results = []

      print_log_paths

      if services.count == 1
        # If the target is only one, it could be console access (TTY)
        # so we can't run in parallel.
        results << services.first.execute
      else
        results = Parallel.map(services, progress: 'Executing', in_processes: 16) do |service|
          service.execute.tap do |success|
            raise Parallel::Kill unless success
          end
        end
      end

      results&.all? { |result| result == true } || terminate_process_group!
    end

    private

    def terminate_process_group!
      pgid = Process.getpgid(Process.pid)

      Process.kill('TERM', -pgid)
    end

    def print_log_paths
      return if command.interactive? || command.quiet?

      log_paths = services.map(&:log_path)
      puts %Q{See the log at \n#{log_paths.join("\n")}}
    end
  end
end
