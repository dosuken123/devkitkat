module Devkitkat
  class Service
    class Driver
      class None < Base
        def prepare
          # no-op
        end

        def cleanup
          # no-op
        end

        def execute(script_file)
          system(script_file)
        end
      end
    end
  end
end
