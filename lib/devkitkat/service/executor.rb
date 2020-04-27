require 'require_all'
require_rel 'concerns/*.rb'
require_rel 'driver/*.rb'
require_rel 'executor/*.rb'
require_rel 'predefined_command/*.rb'

module Devkitkat
  class Service
    class Executor
      include Concerns::ServiceInitializer

      ScriptError = Class.new(StandardError)

      def initialize(service)
        @service = service
      end

      def execute
        logger.new_file

        scripter.new_file do
          if prepare_script
            execute!
          end
        end

        true
      rescue ScriptError => e
        puts "Failure: #{e}".colorize(:red)

        false
      end

      private

      def prepare_script
        scripter.write(variables.to_script)
        scripter.write(logger.to_script) if logger.available?

        if File.exist?(service.script_path)
          scripter.write(%Q{echo "INFO: This script is a custom script."})
          scripter.write(service.script_path)
          @machine_driver = command.options[:driver]
        elsif predefined_command_available?
          scripter.write(%Q{echo "INFO: This script is a predefined script in devkitkat."})
          scripter.write(predefined_command.to_script)
          @machine_driver = predefined_command.machine_driver
        else
          false
        end

        true
      end

      def execute!
        driver = get_driver_klass.new(service)
        driver.prepare

        driver.execute(scripter.file_path).tap do |result|
          raise ScriptError, process_error_message($?) unless result
        end
      ensure
        driver.cleanup
      end

      def scripter
        @scripter ||= Scripter.new(service)
      end

      def logger
        @logger ||= Logger.new(service)
      end

      def variables
        @variables ||= Variables.new(service)
      end

      def predefined_command
        @predefined_command ||= predefined_command_klass.new(service)
      end

      def get_driver_klass
        driver = @machine_driver || service.machine_driver || config.machine_driver

        Object.const_get("Devkitkat::Service::Driver::#{driver.camelize}")
      end

      def predefined_command_klass
        Object.const_get("Devkitkat::Service::PredefinedCommand::#{command.name.camelize}")
      end

      def predefined_command_available?
        Object.const_defined?("Devkitkat::Service::PredefinedCommand::#{command.name.camelize}") &&
          predefined_command.available?
      end

      def process_error_message(exit_code)
        %Q[The command "#{command.script}" for "#{service.name}" exited with non-zero code: #{exit_code}.
  See the log file: #{service.log_path}]
      end
    end
  end
end
