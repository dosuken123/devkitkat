module Devkitkat
  class Service
    class PredefinedCommand
      class Exec < Base
        def to_script
          <<~EOS
            if [ -d "#{service.src_dir}" ]; then
              cd #{service.src_dir}
            fi
            #{command.args.join(' ')}
          EOS
        end

        def available?
          true
        end
      end
    end
  end
end
