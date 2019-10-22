module Devkitkat
  class Command
    attr_reader :options, :script, :target, :args

    def initialize
      @options = {}
      option_parser.parse!

      @script, @target, *@args = ARGV

      show_help if script == 'help'
    end

    def tty?
      options[:tty]
    end

    def variables
      options[:variables]
    end

    def debug?
      options[:debug]
    end

    def tmp_dir
      File.join(kit_root, '.devkitkat')
    end

    def create_tmp_dir
      FileUtils.mkdir_p(tmp_dir)
    end

    def kit_root
      Dir.pwd # TODO: root_path
    end

    private

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: devkitkat <command/script> <target> [args] [options]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-p", "--path PATH", "The root path of the .devkitkat.yml") do |v|
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

        opts.on("-d", "--debug", "Debug mode") do |v|
          options[:debug] = v
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

        opts.on("-v", "--version", "Show version") do |v|
          puts Devkitkat::VERSION
          exit
        end

        opts.on("-h", "--help", "Show help") do |v|
          show_help
        end

        opts.separator ""
        opts.separator "Utility Commands:"
        opts.separator "add-script          - Add a script file"
        opts.separator "add-example         - Add an example file"
        opts.separator "add-shared-script   - Add s shared script"
        opts.separator "help                - Show help"
        opts.separator ""
        opts.separator "Predefined scripts:"
        opts.separator "clone               - Clone repository"
        opts.separator "pull                - Pull latest source code"
        opts.separator "clean               - Clean the service dir"
        opts.separator "poop                - Poop"
      end
    end

    def show_help
      puts option_parser.help
      exit
    end
  end
end
