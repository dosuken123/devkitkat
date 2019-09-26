# This class provides an ability to resolve target into services
module Michi
  class Target
    attr_reader :command

    def initialize(command)
      @command = command
    end

    def resolve
      if system_target?
        [Service.new('system', command)]
      elsif all_services?
        all_services
      elsif group = find_group
        services_for_group(group).map { |service| Service.new(service, command) }
      elsif service = find_service
        [Service.new(service, command)]
      else
        raise ArgumentError, "The target name #{command.target} couldn't be resolved"
      end
    end

    def all_services
      services.map { |key, _| Service.new(key, command) }.tap do |srvs|
        srvs << Service.new('system', command)
      end
    end

    private

    def system_target?
      command.target.nil? || command.target == 'system'
    end

    def all_services?
      command.target == 'all'
    end

    def groups
      command.config.fetch('groups', nil)
    end

    def services
      command.config.fetch('services', nil)
    end

    def services_for_group(group)
      groups.fetch(group, [])
    end

    def find_group
      groups&.keys&.find { |group| group == @command.target }
    end

    def find_service
      services.keys.find { |service| service == @command.target }
    end
  end
end
