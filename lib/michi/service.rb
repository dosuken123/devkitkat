require 'active_support/core_ext/module/delegation'
require 'fileutils'

module Michi
  class Service
    attr_reader :name, :command

    PREDEFINED_SCRIPTS = %w[add-script].freeze

    SUPPORTED_OPTIONS = {
      add_script: %w[--basic]
    }

    BASIC_SCRIPTS = %w[configure unconfigure start stop]
    DIR_NAMES = %w[src script data cache log example dockerfile].freeze

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

    def execute
      if PREDEFINED_SCRIPTS.include?(script)
        method = script.tr('-', '_')
        send(method)
      else
        # TODO: Execute custom script
      end
    end

    def add_script
      FileUtils.mkdir_p(script_path)

      if command.options.any?
        command.options.each do |opt|
          unless SUPPORTED_OPTIONS[__method__.to_sym].include?(opt)
            raise ArgumentError, "The option #{opt} is not supported"
          end
        end
      end

      if command.options.include?('--basic')
        BASIC_SCRIPTS.each do |basic_script|
          file_path = File.join(script_path, basic_script)
          File.write(file_path, SCRIPT_TEMPLATE)
          File.chmod(0777, file_path)
        end
      end
    end
  end
end
