module Michi
  class Executor
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
      puts "See the log at #{log_paths.to_sentence}"

      if target_services.count == 1
        # If the target is only one, it could be console access (TTY)
        # so we can't run in parallel.
        Environment.new(config, command).in do
          target_services.first.execute!
        end
      else
        Parallel.map(target_services, progress: 'Executing', in_processes: 8) do |service|
          Environment.new(config, command).in do
            begin
              service.execute!
            rescue Michi::Service::ScriptError => e
              puts "Failure: #{e}".colorize(:red)
              raise Parallel::Kill
            end
          end
        end
      end
    end

    def target_services
      @target_services ||= config.resolve!(command.target, exclude: command.options[:exclude])
                                  .map { |service| Service.new(service, config, command) }
    end
  end
end
