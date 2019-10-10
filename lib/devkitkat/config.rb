module Devkitkat
  class Config
    DEVKITKAT_FILE_NAME = '.devkitkat.yml'
    HIDDEN_SERVICES = %w[system]
    DEFAULT_APPLICATION_NAME = 'devkitkat'
    DEFAULT_IMAGE = 'ubuntu:18.04'

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
                 elsif service = find_service(target)
                   [service]
                 else
                   raise ArgumentError, "The target name #{target} couldn't be resolved"
                 end

      services = services - exclude if exclude

      services
    end

    def environment_type
      if devkitkat_yml.key?('image')
        'docker'
      else
        'local'
      end
    end

    def image_base
      if devkitkat_yml['image'].is_a?(String)
        devkitkat_yml['image']
      elsif devkitkat_yml['image'].is_a?(Hash)
        devkitkat_yml.dig('image', 'base')
      end || DEFAULT_IMAGE
    end

    def image_install
      devkitkat_yml.dig('image', 'install') || []
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

    def load_config
      File.read(config_path).yield_self do |content|
        YAML.load(content)
      end
    end

    def config_path
      File.join(kit_root, DEVKITKAT_FILE_NAME)
    end
  end
end
