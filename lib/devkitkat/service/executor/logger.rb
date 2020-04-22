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

        def new_file
          FileUtils.rm_f(service.log_path)
          FileUtils.mkdir_p(service.log_dir)
        end
      end
    end
  end
end
