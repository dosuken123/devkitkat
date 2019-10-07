module Devkitkat
  class Command
    attr_reader :options, :script, :target, :args

    def initialize
      @options = {}

      OptionParser.new do |opts|
        opts.banner = "Usage: devkitkat <script> <target> [options]"

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

      @script, @target, *@args = ARGV
    end

    def tty?
      options[:tty]
    end

    def variables
      options[:variables]
    end

    def tmp_dir
      File.join(kit_root, 'tmp')
    end

    def create_tmp_dir
      FileUtils.mkdir_p(tmp_dir)
    end

    def kit_root
      Dir.pwd # TODO: root_path
    end
  end
end
