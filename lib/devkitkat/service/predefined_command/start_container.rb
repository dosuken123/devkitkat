module Devkitkat
  class Service
    class PredefinedCommand
      class StartContainer < Base
        def to_script
          <<~EOS
            tail -f
          EOS
        end

        def available?
          true
        end

        def machine_driver
          'docker'
        end
      end
    end
  end
end
