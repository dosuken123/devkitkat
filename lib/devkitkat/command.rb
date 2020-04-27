require 'optparse'

module Devkitkat
  class Command
    attr_reader :options, :script, :target, :args

    def initialize
      @options = {}
      option_parser.parse!

      @script, @target, *@args = ARGV

      show_help if script == 'help'
      show_version if script == 'version'
    end

    def interactive?
      options[:interactive]
    end

    def variables
      options[:variables]
    end

    def debug?
      options[:debug]
    end

    def quiet?
      options[:quiet]
    end

    def kit_root
      options[:root_path] || Dir.pwd
    end

    def name
      script.tr('-', '_')
    end

    private

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: devkitkat <command/script> <target> [args] [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-d", "--driver", "Machine Driver") do |v|
          options[:driver] = v
        end

        opts.on("-d", "--debug", "Debug mode") do |v|
          options[:debug] = v
        end

        opts.on("-e", "--exclude SERVICE", "Exclude serviced from the specified target") do |v|
          options[:exclude] ||= []
          options[:exclude] << v
        end

        opts.on("-e", "--env-var VARIABLE", "additional environment variables") do |v|
          options[:variables] ||= {}
          options[:variables].merge!(Hash[*v.split('=')])
        end

        opts.on("-h", "--help", "Show help") do |v|
          show_help
        end

        opts.on("-i", "--interactive", "Interactive mode. STDOUT is streamed in console.") do |v|
          options[:interactive] = v
        end

        opts.on("-p", "--path PATH", "The root path of the .devkitkat.yml") do |v|
          options[:root_path] = v
        end

        opts.on("-q", "--quiet", 'Quiet mode') do |v|
          options[:quiet] = v
        end

        opts.on("-v", "--version", "Show version") do |v|
          puts Devkitkat::VERSION
          exit
        end

        opts.separator ""
        opts.separator "Utility Commands:"
        opts.separator "add-script          - Add a script file"
        opts.separator "add-example         - Add an example file"
        opts.separator "add-shared-script   - Add s shared script"
        opts.separator "help                - Show help"
        opts.separator ""
        opts.separator "Predefined scripts:"
        opts.separator "clone               - Clone repository (Available options: `GIT_DEPTH`)"
        opts.separator "pull                - Pull latest source code"
        opts.separator "clean               - Clean the service dir"
        opts.separator "poop                - Poop"
        opts.separator "show-variables      - Show all variables via 'export' command"
        opts.separator "remove-containers   - Remove all related containers"
      end
    end

    def show_help
      puts option_parser.help
      exit
    end

    def show_version
      puts Devkitkat::VERSION
      exit
    end
  end
end
