require "michi/version"
require "michi/service"
require "michi/target"
require 'yaml'

module Michi
  class Command
    MICHI_FILE_NAME = '.michi.yml'

    attr_reader :config, :options, :script, :target

    def initialize(args = nil)
      @config = load_config
      options = args.select { |arg| %r{^--}.match(arg) }
      @script, @target = args - options

      @options = options.inject({}) do |hash, opt|
        key, value = opt.split('=')
        hash[key] = value
        hash
      end

      puts "config: #{@config}"
      puts "options: #{@options}"
      puts "script: #{@script}"
      puts "target: #{@target}"
    end

    def execute
      target = Michi::Target.new(self)

      inject_global_variables
      target.all_services.map(&:inject_public_variables)

      target.resolve.each do |service| # TODO: Concurrent run
        service.execute
      end
    end

    private

    def load_config
      File.read(config_path).yield_self do |content|
        YAML.load(content)
      end
    end

    def config_path
      File.join(Dir.pwd, MICHI_FILE_NAME)
    end

    def inject_global_variables
      config.fetch('variables', {}).each do |key, value|
        ENV[key.upcase] = value.to_s
      end

      ENV["MI_ENVIRONMENT"] = environment.to_s
      ENV["MI_APPLICATION"] = application.to_s
    end

    def environment
      config.dig('environment', 'type') || 'local'
    end

    def application
      config.fetch('application', '')
    end
  end
end
