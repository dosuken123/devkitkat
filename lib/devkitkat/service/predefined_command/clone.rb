require 'devkitkat/service/predefined_command/base'

module Devkitkat
  class Service
    class PredefinedCommand
      class Clone < Base
        def to_script
          <<~EOS
            set -e

            if [ -n "$GIT_DEPTH" ]; then
              git clone #{service.repo} #{service.src_dir} --depth $GIT_DEPTH
            else
              git clone #{service.repo} #{service.src_dir}
            fi
          EOS
        end

        def available?
          service.repo_defined?
        end

        def machine_driver
          'none'
        end
      end
    end
  end
end
