require "devkitkat/version"
require "devkitkat/command"
require "devkitkat/config"
require "devkitkat/service"
require "devkitkat/processor"
require 'colorize'
require 'active_support/core_ext/array/conversions'

module Devkitkat
  class Main
    def self.execute
      command = Command.new
      config = Config.new(command.kit_root)

      target_services = config.resolve!(command.target, exclude: command.options[:exclude])
                              .map { |name| Service.new(name, config, command) }

      Processor.new(target_services, command, config).execute
    end
  end
end
