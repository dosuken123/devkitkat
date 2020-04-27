require 'devkitkat/service/predefined_command/base'

module Devkitkat
  class Service
    class PredefinedCommand
      class AddSharedScript < Base
        def to_script
          <<~EOS
            mkdir -p #{service.script_dir}
            touch #{service.shared_script_path}
            chmod 755 #{service.shared_script_path}
          EOS
        end

        def available?
          service.system? && !File.exist?(service.shared_script_path)
        end

        def machine_driver
          'none'
        end
      end
    end
  end
end
