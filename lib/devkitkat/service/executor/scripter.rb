module Devkitkat
  class Service
    class Executor
      class Scripter
        include Concerns::ServiceInitializer

        SCRIPT_HEADER = <<~EOS
          #!/bin/bash
        EOS

        def file_path
          File.join(service.dir, "script-#{service.name}-#{command.script}")
        end

        def new_file
          delete_file
          create_file

          yield
        ensure
          delete_file
        end

        def write(cmd)  
          File.open(file_path, 'a') do |stream|
            stream.write(cmd + "\n")
          end
        end

        private

        def create_file
          ensure_service_root_dir
          File.write(file_path, SCRIPT_HEADER)
          File.chmod(0777, file_path)
        end

        def delete_file
          FileUtils.rm_f(file_path)
        end

        def ensure_service_root_dir
          FileUtils.mkdir_p(service.root_dir)
        end
      end
    end
  end
end
