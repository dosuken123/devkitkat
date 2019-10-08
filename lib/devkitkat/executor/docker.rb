require 'active_support/core_ext/module/delegation'
require 'docker'

module Devkitkat
  class Executor
    class Docker
      attr_reader :service, :script_file

      delegate :config, :command, to: :service

      def initialize(service)
        @service = service
      end

      def prepare
        pull_image
        start_container
      end

      def cleanup
        stop_container
      end

      def commit(script_file)
        @script_file = script_file

        rewrite_root_path!
        new_path = script_path_in_container

        container.exec([new_path])
      end

      private
  
      def rewrite_root_path!
        content = File.read(script_file)
        new_content = content.gsub(command.kit_root, root_in_container)
        File.write(script_file, new_content)
      end

      def script_path_in_container
        relative_path = script_file.delete_prefix(command.kit_root)
        File.join(root_in_container, relative_path)
      end

      def log_path_in_container
        relative_path = service.log_path.delete_prefix(command.kit_root)
        File.join(root_in_container, relative_path)
      end

      def docker_image
        config.environment_image
      end
  
      def container
        @container ||= ::Docker::Container.create(container_parameter)
      end
  
      def container_parameter
        # TODO: Speicfy users otherwise the created files are owned by root
        params = {
          'Cmd' => %w[tail -f],
          'Image' => docker_image,
          'name' => service.container_name,
          'HostConfig' => {
            'Binds' => ["#{command.kit_root}:#{root_in_container}"]
          }
        }

        if service.port
          params.deep_merge!(
            'ExposedPorts' => { "#{service.port}/tcp" => {} },
            'HostConfig' => {
              'PortBindings' => {
                "#{service.port}/tcp" => [{ 'HostPort' => service.port.to_s }]
              }
            }
          )
        end

        params
      end

      def root_in_container
        "/devkitkat"
      end

      def pull_image
        ::Docker::Image.create('fromImage' => docker_image)
      end

      def start_container
        container.start
      end
  
      def stop_container
        container.stop
        container.remove
      end
    end
  end
end
