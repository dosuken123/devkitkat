module Michi
  class Main
    attr_reader :config, :command

    def initialize
      @config = Config.new
      @command = Command.new
    end

    def execute
      if command.tty? && target_services.count > 1
        raise ArgumentError, 'TTY mode accepts only one service'
      end

      log_paths = target_services.map(&:log_path)
      puts %Q{See the log at \n#{log_paths.join("\n")}}

      if target_services.count == 1
        # If the target is only one, it could be console access (TTY)
        # so we can't run in parallel.
        service = target_services.first
        execute_for(service)
      else
        Parallel.map(target_services, progress: 'Executing', in_processes: 8) do |service|
          execute_for(service)
        end
      end
    end

    private

    def execute_for(service)
      begin
        service.execute!
      rescue Michi::Service::ScriptError => e
        puts "Failure: #{e}".colorize(:red)
        raise Parallel::Kill
      end
    end

    def target_services
      @target_services ||= config.resolve!(command.target, exclude: command.options[:exclude])
                                  .map { |name| Service.new(name, config, command) }
    end
  end
end
