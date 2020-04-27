require 'devkitkat/service/predefined_command/base'

module Devkitkat
  class Service
    class PredefinedCommand
      class AddExample < Base
        def to_script
          names = command.args

          raise ArgumentError, 'Please specify at least one example name' if names.empty?

          FileUtils.mkdir_p(service.example_dir)

          names.map do |name|
            file_path = File.join(service.example_dir, name)

            <<-EOS
if [[ ! -f "#{file_path}" ]]; then
  touch #{file_path}
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

