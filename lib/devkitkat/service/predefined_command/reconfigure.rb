module Devkitkat
  class Service
    class PredefinedCommand
      class Reconfigure < Base
        def to_script
          unconfigure_path = File.join(service.script_dir, 'unconfigure')
          configure_path = File.join(service.script_dir, 'configure')

          <<~EOS
            if [[ -f "#{unconfigure_path}" ]]; then
              #{unconfigure_path}
            fi

            if [[ -f "#{configure_path}" ]]; then
              #{configure_path}
            fi
          EOS
        end

        def available?
          true
        end
      end
    end
  end
end
