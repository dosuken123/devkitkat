require 'devkitkat/service/predefined_command/base'

module Devkitkat
  class Service
    class PredefinedCommand
      class AddScript < Base
        def to_script
          names = command.args.any? ? command.args : %w[configure unconfigure start]

          FileUtils.mkdir_p(service.script_dir)

          names.map do |name|
            file_path = File.join(service.script_dir, name)

            <<-EOS
if [[ ! -f "#{file_path}" ]]; then
  cat > #{file_path} << EOL
#!/bin/bash
set -e

# TODO: Define scripts
EOL
  chmod 755 #{file_path}
fi
            EOS
          end.join("\n")
        end

        def available?
          true
        end

        def machine_driver
          'none'
        end
      end
    end
  end
end
