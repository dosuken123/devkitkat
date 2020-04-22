module Devkitkat
  class Service
    class PredefinedCommand
      class Exec < Base
        def to_script
          <<~EOS
            cd #{service.src_dir}
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
