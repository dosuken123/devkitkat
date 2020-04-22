module Devkitkat
  class Service
    class PredefinedCommand
      class Poop < Base
        def to_script
          <<~EOS
            echo "💩"
          EOS
        end

        def available?
          true
        end
      end
    end
  end
end
