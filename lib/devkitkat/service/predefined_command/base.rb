module Devkitkat
  class Service
    class PredefinedCommand
      class Base
        include Concerns::ServiceInitializer

        def to_script
          raise NotImplementedError
        end

        def available?
          raise NotImplementedError
        end

        def machine_driver
          nil
        end
      end
    end
  end
end
