require 'devkitkat/service/predefined_command/base'

module Devkitkat
  class Service
    class PredefinedCommand
      class AddGitIgnore < Base
        def to_script
          <<~EOS
cat > #{file_path} << EOL
services/**/script-*
services/**/src
services/**/log
services/**/cache
services/**/data
EOL
          EOS
        end

        def available?
          service.system? && !File.exist?(file_path)
        end

        def file_path
          File.join(command.kit_root, '.gitignore')
        end
      end
    end
  end
end
