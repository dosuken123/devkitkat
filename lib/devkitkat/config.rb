require 'yaml'

module Devkitkat
  class Config
    DEVKITKAT_FILE_NAME = '.devkitkat.yml'
    HIDDEN_SERVICES = %w[system]
    DEFAULT_APPLICATION_NAME = 'devkitkat'

    attr_reader :devkitkat_yml, :kit_root

    def initialize(kit_root)
      @kit_root = kit_root
      @devkitkat_yml = load_config
    end

    def all_services
      services + HIDDEN_SERVICES
    end

    def resolve!(target, exclude: nil)
      services = if target.nil? || target == 'system'
                  %w[system]
                elsif target == 'all'
                  all_services
                elsif group = find_group(target)
                  services_for_group(group)
                elsif services = find_comma_separated_services(target)
                  services
                elsif service = find_service(target)
                  [service]
                else
                  raise_error(target)
                end

      services = services - exclude if exclude

      services
    end

    def machine_driver
      devkitkat_yml.dig('machine', 'driver') || 'none'
    end

    def machine_location
      devkitkat_yml.dig('machine', 'location') || 'local'
    end

    def machine_image
      devkitkat_yml.dig('machine', 'image')
    end

    def machine_extra_hosts
      devkitkat_yml.dig('machine', 'extra_hosts')
    end

    def machine_network_mode
      devkitkat_yml.dig('machine', 'network_mode')
    end

    def machine_extra_write_accesses
      devkitkat_yml.dig('machine', 'extra_write_accesses')
    end

    def application
      devkitkat_yml.fetch('application', DEFAULT_APPLICATION_NAME)
    end

    def variables
      devkitkat_yml.fetch('variables', {})
    end

    def service_hash(name)
      devkitkat_yml.dig('services', name) || {}
    end

    private

    def services
      devkitkat_yml['services']&.keys || []
    end

    def groups
      devkitkat_yml['groups']&.keys || []
    end

    def services_for_group(group)
      devkitkat_yml.dig('groups', group) || []
    end

    def find_group(target)
      groups.find { |group| group == target }
    end

    def find_service(target)
      services.find { |service| service == target }
    end

    def find_comma_separated_services(target)
      return unless target.include?(',')

      target.split(',').map do |t|
        find_service(t).tap do |service|
          raise_error(t) unless service
        end
      end
    end

    def load_config
      File.read(config_path).yield_self do |content|
        YAML.load(content)
      end
    end

    def config_path
      File.join(kit_root, DEVKITKAT_FILE_NAME)
    end

    def raise_error(target)
      raise ArgumentError, "The target name #{target} couldn't be resolved"
    end
  end
end
