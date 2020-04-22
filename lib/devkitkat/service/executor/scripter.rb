module Devkitkat
  class Service
    class Executor
      class Scripter
        include Concerns::ServiceInitializer

        SCRIPT_HEADER = <<~EOS
          #!/bin/bash
        EOS

        def file_path
          File.join(command.tmp_dir, "script-#{service.name}-#{command.script}")
        end
  
        def delete_file
          FileUtils.rm_f(file_path)
        end

        def write(cmd)
          ensure_script_file
  
          File.open(file_path, 'a') do |stream|
            stream.write(cmd + "\n")
          end
        end

        private

        def ensure_script_file
          create_script_file unless File.exist?(file_path)
        end

        def create_script_file
          command.create_tmp_dir
          File.write(file_path, SCRIPT_HEADER)
          File.chmod(0777, file_path)
        end
      end
    end
  end
end
