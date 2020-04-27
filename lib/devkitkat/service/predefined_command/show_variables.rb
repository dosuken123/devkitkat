module Devkitkat
  class Service
    class PredefinedCommand
      class ShowVariables < Base
        def to_script
          <<~EOS
            export
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
