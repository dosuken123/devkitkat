module Michi
  class Environment
    attr_reader :command, :config

    def initialize(config, command)
      @config, @command = config, command
    end

    def in
      inject_global_variables
      all_services.each { |service| service.inject_public_variables }

      yield
    end

    private

    def inject_global_variables
      config.variables.each do |key, value|
        ENV[key] = value.to_s
      end

      ENV["MI_ENVIRONMENT_TYPE"] = config.environment_type.to_s
      ENV["MI_APPLICATION"] = config.application.to_s
    end

    def all_services
      @all_services ||= config.all_services.map { |service| Service.new(service, config, command) }
    end
  end
end
