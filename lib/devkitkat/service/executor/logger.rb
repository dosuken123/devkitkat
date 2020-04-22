module Devkitkat
  class Service
    class Executor
      class Logger
        include Concerns::ServiceInitializer

        def to_script
          "exec > #{service.log_path} 2>&1"
        end

        def available?
          !command.interactive?
        end
      end
    end
  end
end
