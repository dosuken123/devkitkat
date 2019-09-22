# encoding: UTF-8

require 'active_support/core_ext/module/delegation'
require 'fileutils'
require 'rugged'

module Michi
  class Service
    attr_reader :name, :command

    ScriptError = Class.new(StandardError)

    DIVISIONS = %w[src script data cache log example dockerfile].freeze
    SERVICE_PROPERTIES = %w[repo host port]

    SCRIPT_TEMPLATE = <<-EOS
#!/bin/bash

# TODO: Define scripts
    EOS

    delegate :script, :config, to: :command

    def initialize(name, command)
      @name, @command = name, command
    end

    def execute!
      FileUtils.rm_f(log_path)
      FileUtils.mkdir_p(log_dir)

      method = script.tr('-', '_')

      if File.exist?(script_path)
        inject_private_variables
        process!(%Q{echo "This script is a custom script provided by you."})
        process!(script_path)
      elsif respond_to?(method, true)
        process!(%Q{echo "This script is a predefined script provided by michi."})
        send(method)
      end
    end

    def inject_public_variables
      ENV["MI_#{name.upcase}_DIR"] = service_dir

      DIVISIONS.each do |division|
        ENV["MI_#{name.upcase}_#{division.upcase}_DIR"] = send("#{division}_dir")
      end

      config.dig('services', name).each do |key, value|
        ENV["MI_#{name.upcase}_#{key.upcase}"] = value.to_s
      end
    end

    private

    DIVISIONS.each do |division|
      define_method :"#{division}_dir" do
        File.join(service_dir, division)
      end
    end

    SERVICE_PROPERTIES.each do |property|
      define_method :"#{property}_defined?" do
        service_config.key?(property)
      end

      define_method :"#{property}" do
        service_config[property]
      end
    end

    def service_dir
      File.join(Dir.pwd, 'services', name)
    end

    def script_path
      File.join(script_dir, script)
    end

    def log_path
      File.join(log_dir, "#{script}.log")
    end

    def service_config
      return {} if system?

      config.dig('services', name)
    end

    def system?
      name == 'system'
    end

    def inject_private_variables
      ENV["MI_SELF_DIR"] = service_dir

      DIVISIONS.each do |division|
        ENV["MI_SELF_#{division.upcase}_DIR"] = send("#{division}_dir")
      end

      config.dig('services', name)&.each do |key, value|
        ENV[key] = value.to_s
      end
    end

    def add_script
      names = command.args.any? ? [command.args.first] : %w[configure unconfigure start stop]

      FileUtils.mkdir_p(script_dir)

      names.each do |name|
        file_path = File.join(script_dir, name)

        next if File.exist?(file_path)

        File.write(file_path, SCRIPT_TEMPLATE)
        File.chmod(0777, file_path)
      end
    end

    def process!(cmd_line)
      if command.options[:tty]
        system(cmd_line)
      else
        system("#{cmd_line} >> #{log_path} 2>&1").tap do |result|
          raise ScriptError, process_error_message($?) unless result
        end
      end
    end

    def process_error_message(exit_code)
      %Q[The command "#{script}" for "#{name}" exited with non-zero code: #{exit_code}.
See the log file: #{log_path}]
    end

    def clone
      return unless repo_defined?

      options = []

      if command.options[:git_depth]
        options << "--depth #{command.options[:git_depth]}"
      end

      process!("git clone #{repo} #{src_dir} #{options.join(' ')}")
    end

    def pull
      return unless repo_defined?

      remote = command.options[:git_remote] || 'origin'
      branch = command.options[:git_branch] || 'master'

      process!("git pull #{remote} #{branch}")
    end

    def clean
      FileUtils.rm_rf(src_dir)
      FileUtils.rm_rf(data_dir)
      FileUtils.rm_rf(cache_dir)
      FileUtils.rm_rf(log_dir)
    end

    def reconfigure
      process!(File.join(script_dir, 'unconfigure'))
      process!(File.join(script_dir, 'configure'))
    end

    def poop
      process!(%Q{echo "💩"})
    end
  end
end
