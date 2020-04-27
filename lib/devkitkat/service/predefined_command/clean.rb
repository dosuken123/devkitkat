require 'devkitkat/service/predefined_command/base'

module Devkitkat
  class Service
    class PredefinedCommand
      class Clean < Base
        def to_script
          <<~EOS
            rm -rf #{service.src_dir}
            rm -rf #{service.data_dir}
            rm -rf #{service.cache_dir}
            rm -rf #{service.log_dir}
          EOS
        end

        def available?
          true
        end

        def machine_driver
          'none'
        end
      end
    end
  end
end
