module Devkitkat
  class Main
    attr_reader :config, :command

    def initialize
      @command = Command.new
      @config = Config.new(command.kit_root)
    end

    def execute
      if command.tty? && target_services.count > 1
        raise ArgumentError, 'TTY mode accepts only one service'
      end

      results = []

      print_log_paths

      if target_services.count == 1
        # If the target is only one, it could be console access (TTY)
        # so we can't run in parallel.
        results << target_services.first.execute
      else
        results = Parallel.map(target_services, progress: 'Executing', in_processes: 8) do |service|
          service.execute.tap do |success|
            raise Parallel::Kill unless success
          end
        end
      end

      exit(1) unless results&.all? { |result| result == true }
    end

    private

    def target_services
      @target_services ||= config.resolve!(command.target, exclude: command.options[:exclude])
                                 .map { |name| Service.new(name, config, command) }
    end

    def print_log_paths
      return if command.tty?

      log_paths = target_services.map(&:log_path)
      puts %Q{See the log at \n#{log_paths.join("\n")}}
    end
  end
end
