module Michi
  class Config
    MICHI_FILE_NAME = '.michi.yml'
    HIDDEN_SERVICES = %w[system]

    attr_reader :michi_yml

    def initialize
      @michi_yml = load_config
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
                 elsif service = find_service(target)
                   [service]
                 else
                   raise ArgumentError, "The target name #{target} couldn't be resolved"
                 end

      services = services - exclude if exclude

      services
    end

    def environment_type
      michi_yml.dig('environment', 'type') || 'local'
    end

    def application
      michi_yml.fetch('application', '')
    end

    def variables
      michi_yml.fetch('variables', {})
    end

    def service_hash(name)
      michi_yml.dig('services', name) || {}
    end

    private

    def services
      michi_yml['services']&.keys || []
    end

    def groups
      michi_yml['groups']&.keys || []
    end

    def services_for_group(group)
      michi_yml.dig('groups', group) || []
    end

    def find_group(target)
      groups.find { |group| group == target }
    end

    def find_service(target)
      services.find { |service| service == target }
    end

    def load_config
      File.read(config_path).yield_self do |content|
        YAML.load(content)
      end
    end

    def config_path
      File.join(Dir.pwd, MICHI_FILE_NAME)
    end
  end
end