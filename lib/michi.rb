require "michi/version"
require "michi/service"
require "michi/target"
require 'yaml'
require 'optparse'

module Michi
  class Command
    MICHI_FILE_NAME = '.michi.yml'

    attr_reader :config, :options, :script, :target, :args

    def initialize
      @options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: michi <script> <target> [options]"

        opts.on("-p", "--path PATH", "The root path of the .michi.yml") do |v|
          options[:root_path] = v
        end

        opts.on("-e", "--exclude SERVICE", "Exclude serviced from the specified target") do |v|
          options[:exclude] ||= []
          options[:exclude] << v
        end

        opts.on("-e", "--env-var VARIABLE", "additional environment variables") do |v|
          options[:variables] ||= {}
          options[:variables].merge!(Hash[*v.split('=')])
        end

        opts.on("-d", "--depth DEPTH", "Git depth for pull/fetch") do |v|
          options[:git_depth] = v
        end

        opts.on("-r", "--remote REMOTE", "Git remote") do |v|
          options[:git_remote] = v
        end

        opts.on("-b", "--branch BRANCH", "Git branch") do |v|
          options[:git_branch] = v
        end

        opts.on("-t", "--tty", "TTY mode. In this mode, log won't be emitted.") do |v|
          options[:tty] = v
        end
      end.parse!

      @config = load_config
      @script, @target, *@args = ARGV

      puts "config: #{@config}"
      puts "options: #{@options}"
      puts "script: #{@script}"
      puts "target: #{@target}"
      puts "args: #{@args}"
    end

    def execute
      target = Michi::Target.new(self)

      inject_global_variables
      target.all_services.map(&:inject_public_variables)

      services = target.resolve

      raise ArgumentError, 'TTY mode accepts only one service' if options[:tty] && services.count != 1

      if services.count == 1
        # If the target is only one, it could be console access (TTY)
        # so we can't run in parallel.
        services.first.execute!
      else
        threads = services.map do |service|
          Thread.new { service.execute! }
        end

        threads.each(&:join)
      end
    rescue ScriptError => e
      puts "Failed to execute: #{e}"
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
        ENV[key] = value.to_s
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
