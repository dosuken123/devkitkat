require 'docker'
require_relative 'docker/container'
require_relative 'docker/image'

module Devkitkat
  class Service
    class Driver
      class Docker < Base
        attr_reader :script_file

        def prepare
          image.pull
          container.start
        end

        def execute(script_file)
          @script_file = script_file

          rewrite_root_path!
          new_path = script_path_in_container

          container.exec([new_path])
        end

        def cleanup
          container.stop
        end

        private

        def rewrite_root_path!
          content = File.read(script_file)
          new_content = content.gsub(command.kit_root, Container::ROOT_IN_CONTAINER)
          File.write(script_file, new_content)
        end

        def script_path_in_container
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
