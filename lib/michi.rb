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
      services = Michi::Target.new(self).resolve

      services.each do |service| # TODO: Concurrent run
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
  end
end
