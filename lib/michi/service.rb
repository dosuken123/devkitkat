require 'active_support/core_ext/module/delegation'
require 'fileutils'

module Michi
  class Service
    attr_reader :name, :command

    PREDEFINED_SCRIPTS = %w[add-script clone].freeze

    SUPPORTED_OPTIONS = {
      add_script: %w[--basic --name]
    }

    BASIC_SCRIPTS = %w[configure unconfigure start stop]
    DIR_NAMES = %w[src script data cache log example dockerfile].freeze
    SERVICE_PROPERTIES = %w[repo host port]

    SCRIPT_TEMPLATE = <<-EOS
#!/bin/bash

# TODO: Define scripts
    EOS

    delegate :script, to: :command

    def initialize(name, command)
      @name, @command = name, command
    end

    DIR_NAMES.each do |dir|
      define_method :"#{dir}_path" do
        File.join(Dir.pwd, 'services', name, dir)
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

    def service_config
      command.config.dig('services', name)
    end

    def execute
      if PREDEFINED_SCRIPTS.include?(script)
        method = script.tr('-', '_')
        send(method)
      else
        # TODO: Execute custom script
      end
    end

    def validate_options!(script)
      command.options.each do |key, value|
        unless SUPPORTED_OPTIONS[script.to_sym].include?(key)
          raise ArgumentError, "The option #{key} is not supported"
        end
      end
    end

    def add_script
      validate_options!(__method__) if command.options.any?

      names = if command.options.key?('--basic')
                BASIC_SCRIPTS
              elsif command.options.key?('--name')
                [command.options['--name']]
              else
                raise ArgumentError, "#{__method__}: Name is not specified"
              end

      FileUtils.mkdir_p(script_path)

      names.each do |name|
        file_path = File.join(script_path, name)
        File.write(file_path, SCRIPT_TEMPLATE)
        File.chmod(0777, file_path)
      end
    end

    def clone
      return unless repo_defined?

      # TODO: Clone repo via rugged
      repo
    end
  end
end
