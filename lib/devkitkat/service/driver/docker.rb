require 'docker'
require_relative 'docker/container'
require_relative 'docker/image'

module Devkitkat
  class Service
    class Driver
      class Docker < Base
        def prepare
          image.pull
          container.start
        end

        def execute(script_file)
          new_path = rewrite_root_path!(script_file)

          if config.machine_root_user
            container.exec_as_root([new_path])
          else
            container.exec([new_path])
          end
        end

        def cleanup
          container.stop
        end

        private

        def rewrite_root_path!(script_file)
          content = File.read(script_file)
          new_content = content.gsub(command.kit_root, Container::ROOT_IN_CONTAINER)
          File.write(script_file, new_content)

          relative_path = script_file.delete_prefix(command.kit_root)
          File.join(Container::ROOT_IN_CONTAINER, relative_path)
        end

        def container
          @container ||= Container.new(service)
        end

        def image
          @image ||= Image.new(service)
        end
      end
    end
  end
end
