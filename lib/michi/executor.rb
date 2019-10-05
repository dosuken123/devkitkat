require "michi/executor/docker"
require "michi/executor/local"

module Michi
  class Executor
    attr_reader :service, :scripts

    delegate :config, :command, to: :service
    delegate :prepare, :cleanup, to: :executor

    SCRIPT_HEADER = <<-EOS
#!/bin/bash
set -e
    EOS

    def initialize(service)
      @service = service
      delete_script_file
    end

    def write(cmd)
      ensure_script_file

      File.open(script_file, 'a') do |stream|
        stream.write(cmd + "\n")
      end
    end

    def commit
      executor.commit(script_file)
    ensure
      delete_script_file
    end

    private

    def executor
      @executor ||= klass.new(service)
    end

    def klass
      Object.const_get("Michi::Executor::#{config.environment_type.capitalize}")
    end

    def script_file
      File.join(command.tmp_dir, "script-#{service.name}-#{command.script}")
    end

    def ensure_script_file
      create_script_file unless File.exist?(script_file)
    end

    def create_script_file
      command.create_tmp_dir
      File.write(script_file, SCRIPT_HEADER)
      File.chmod(0777, script_file)
    end

    def delete_script_file
      FileUtils.rm_f(script_file)
    end
  end
end
