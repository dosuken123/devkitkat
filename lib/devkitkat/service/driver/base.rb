module Devkitkat
  class Service
    class Driver
      class Base
        include Concerns::ServiceInitializer

        PreparationError = Class.new(StandardError)

        def prepare
          raise NotImplementedError
        end

        def cleanup
          raise NotImplementedError
        end

        def execute(script_file)
          raise NotImplementedError
        end
      end
    end
  end
end
