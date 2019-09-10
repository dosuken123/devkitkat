# This class provides an ability to resolve target into services
module Michi
  class Target
    attr_reader :command

    def initialize(command)
      @command = command
    end

    def resolve
      if all_services?
        services.map { |key, value| Service.new(key, @command) }
      elsif group = find_group
        services_for_group(group).map { |service| Service.new(service, @command) }
      else
        [Service.new(service_for_target, @command)]
      end
    end

    private

    def all_services?
      @command.target == 'all'
    end

    def groups
      @command.config.fetch('groups', nil)
    end

    def services
      @command.config.fetch('services', nil)
    end

    def services_for_group(group)
      groups.fetch(group, [])
    end

    def service_for_target
      services[@command.target]
    end

    def find_group
      groups.keys.find { |group| group == @command.target }
    end
  end
end
