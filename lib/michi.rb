require "michi/version"
require 'yaml'

module Michi
  class Command
    MICHI_FILE_NAME = '.michi.yml'

    def execute(args = nil)
      puts "config: #{config}"

      options = args.select { |arg| %r{^--}.match(arg) }
      commands = args - options

      puts "options: #{options}"
      puts "commands: #{commands}"
    end

    private

    def config
      return @config if defined?(@config)

      File.read(config_path).yield_self do |content|
        @config = YAML.load(content)
      end
    end

    def config_path
      File.join(Dir.pwd, MICHI_FILE_NAME)
    end
  end
end
