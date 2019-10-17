# encoding: UTF-8

require 'fileutils'

module Devkitkat
  class Service
    attr_reader :name, :config, :command, :executor

    ScriptError = Class.new(StandardError)

    DIVISIONS = %w[src script data cache log example dockerfile].freeze
    SERVICE_PROPERTIES = %w[repo host port]

    SCRIPT_TEMPLATE = <<-EOS
#!/bin/bash
set -e

# TODO: Define scripts
    EOS

    delegate :options, :script, :args, :kit_root, to: :command

    def initialize(name, config, command)
      @name, @config, @command = name, config, command
    end

    def execute
      execute!

      true
    rescue ScriptError => e
      puts "Failure: #{e}".colorize(:red)

      false
    end

    def execute!
      executor.prepare

      inject_global_variables
      inject_public_variables
      inject_private_variables
      setup_logger

      FileUtils.rm_f(log_path)
      FileUtils.mkdir_p(log_dir)

      method = script.tr('-', '_')

      if File.exist?(script_path)
        executor.write(%Q{echo "This script is a custom script provided by you."})
        executor.write(script_path)
      elsif respond_to?(method, true)
        executor.write(%Q{echo "This script is a predefined script provided by devkitkat."})
        send(method)
      end

      executor.commit.tap do |result|
        raise ScriptError, process_error_message($?) unless result
      end
    ensure
      executor.cleanup
    end

    def log_path
      File.join(log_dir, "#{script}.log")
    end

    def container_name
      "#{config.application}-#{name}"
    end

    DIVISIONS.each do |division|
      define_method :"#{division}_dir" do
        File.join(service_dir, division)
      end
    end

    SERVICE_PROPERTIES.each do |property|
      define_method :"#{property}_defined?" do
        config.service_hash(name).key?(property)
      end

      define_method :"#{property}" do
        config.service_hash(name)[property]
      end
    end

    def service_dir
      File.join(kit_root, 'services', name)
    end

    def shared_script_dir
      File.join(script_dir, 'shared')
    end

    private

    def inject_global_variables
      config.variables.each do |key, value|
        executor.write("export #{key}=#{value}")
      end

      command.variables&.each do |key, value|
        executor.write("export #{key}=#{value}")
      end

      executor.write("export MI_ROOT_DIR=#{kit_root}")
      executor.write("export MI_ENVIRONMENT_TYPE=#{config.environment_type.to_s}")
      executor.write("export MI_APPLICATION=#{config.application.to_s}")
    end

    def inject_public_variables
      all_services.each do |service|
        executor.write("export MI_#{service.name.upcase}_DIR=#{service.service_dir}")

        DIVISIONS.each do |division|
          executor.write("export MI_#{service.name.upcase}_#{division.upcase}_DIR=#{service.send("#{division}_dir")}")
        end

        executor.write("export MI_#{service.name.upcase}_SHARED_SCRIPT_DIR=#{service.shared_script_dir}")

        config.service_hash(service.name).each do |key, value|
          executor.write("export MI_#{service.name.upcase}_#{key.upcase}=#{value}")
        end
      end
    end

    def inject_private_variables
      executor.write("export MI_SELF_DIR=#{service_dir}")

      DIVISIONS.each do |division|
        executor.write("export MI_SELF_#{division.upcase}_DIR=#{send("#{division}_dir")}")
      end

      config.service_hash(name).each do |key, value|
        executor.write("export #{key}=#{value}")
      end
    end

    def setup_logger
      return if command.tty?

      executor.write("exec > #{log_path} 2>&1")
    end

    def all_services
      @all_services ||= config.all_services.map { |service| Service.new(service, config, command) }
    end

    def script_path
      File.join(script_dir, script)
    end

    def system?
      name == 'system'
    end

    def process_error_message(exit_code)
      %Q[The command "#{script}" for "#{name}" exited with non-zero code: #{exit_code}.
See the log file: #{log_path}]
    end

    def add_script
      names = command.args.any? ? command.args : %w[configure unconfigure start]

      FileUtils.mkdir_p(script_dir)

      names.each do |name|
        file_path = File.join(script_dir, name)

        next if File.exist?(file_path)

        File.write(file_path, SCRIPT_TEMPLATE)
        File.chmod(0777, file_path)
      end
    end

    def add_example
      names = command.args

      raise ArgumentError, 'Please specify at least one example name' if names.empty?

      FileUtils.mkdir_p(example_dir)

      names.each do |name|
        file_path = File.join(example_dir, name)

        next if File.exist?(file_path)

        FileUtils.touch(file_path)
        File.chmod(0777, file_path)
      end
    end

    def add_shared_script
      raise ArgumentError, %Q{Shared script has to be added to "system"} unless name == 'system'

      FileUtils.mkdir_p(script_dir)

      file_path = File.join(script_dir, 'shared')

      return if File.exist?(file_path)

      FileUtils.touch(file_path)
      File.chmod(0777, file_path)
    end

    def clone
      return unless repo_defined?

      options = []

      if command.options[:git_depth]
        options << "--depth #{command.options[:git_depth]}"
      end

      executor.write("git clone #{repo} #{src_dir} #{options.join(' ')}")
    end

    def pull
      return unless repo_defined?

      remote = command.options[:git_remote] || 'origin'
      branch = command.options[:git_branch] || 'master'

      executor.write("git pull #{remote} #{branch}")
    end

    def clean
      executor.write("rm -rf #{src_dir}")
      executor.write("rm -rf #{data_dir}")
      executor.write("rm -rf #{cache_dir}")
      executor.write("rm -rf #{log_dir}")
    end

    def reconfigure
      unconfigure_path = File.join(script_dir, 'unconfigure')
      configure_path = File.join(script_dir, 'configure')

      executor.write(unconfigure_path) if File.exist?(unconfigure_path)
      executor.write(configure_path) if File.exist?(configure_path)
    end

    def poop
      executor.write(%Q{echo "💩"})
    end

    def executor
      @executor ||= Executor.new(self)
    end
  end
end
