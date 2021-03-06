# encoding: UTF-8

require 'fileutils'
require "devkitkat/service/executor"

module Devkitkat
  class Service
    attr_reader :name, :config, :command, :executor

    DIVISIONS = %w[src script data cache log example dockerfile].freeze
    SERVICE_PROPERTIES = %w[repo repo_ref host port]

    def initialize(name, config, command)
      @name, @config, @command = name, config, command
    end

    def execute
      Executor.new(self).execute
    end

    DIVISIONS.each do |division|
      define_method :"#{division}_dir" do
        File.join(dir, division)
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

    def root_dir
      File.join(command.kit_root, 'services')
    end

    def dir
      File.join(root_dir, name)
    end

    def log_path
      File.join(log_dir, "#{command.script}.log")
    end

    def script_path
      File.join(script_dir, command.script)
    end

    def system?
      name == 'system'
    end

    def shared_script_path
      return unless system?

      File.join(script_dir, 'shared')
    end

    def machine_driver
      config.service_hash(name).dig('machine', 'driver')
    end
  end
end
