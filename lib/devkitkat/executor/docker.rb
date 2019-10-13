require 'active_support/core_ext/module/delegation'
require 'docker'

module Devkitkat
  class Executor
    class Docker
      attr_reader :service, :script_file

      delegate :config, :command, to: :service

      ROOT_IN_CONTAINER = '/devkitkat'

      def initialize(service)
        @service = service
      end

      def prepare
        pull_image unless image_exist?
        start_container
        sync_user_with_host
      end

      def cleanup
        stop_container
      end

      def commit(script_file)
        @script_file = script_file

        rewrite_root_path!
        new_path = script_path_in_container

        container.exec([new_path], user: user_name)
      end

      private
  
      def rewrite_root_path!
        content = File.read(script_file)
        new_content = content.gsub(command.kit_root, ROOT_IN_CONTAINER)
        File.write(script_file, new_content)
      end

      def script_path_in_container
        relative_path = script_file.delete_prefix(command.kit_root)
        File.join(ROOT_IN_CONTAINER, relative_path)
      end

      def log_path_in_container
        relative_path = service.log_path.delete_prefix(command.kit_root)
        File.join(ROOT_IN_CONTAINER, relative_path)
      end

      def docker_image
        config.image
      end
  
      def container
        @container ||= ::Docker::Container.create(container_parameter)
      end
  
      def container_parameter
        params = {
          'Cmd' => %w[tail -f],
          'Image' => docker_image,
          'name' => service.container_name,
          'HostConfig' => {
            'Binds' => ["#{command.kit_root}:#{ROOT_IN_CONTAINER}"]
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

      def pull_image
        puts "Pulling image #{docker_image}..."
        ::Docker::Image.create('fromImage' => docker_image)
        puts "Pulled image #{docker_image}..."
      end

      def image_exist?
        ::Docker::Image.get(docker_image)
      rescue
        false
      end

      def start_container
        container.start
      end

      def user_name
        'devkitkat'
      end

      def group_id
        @group_id ||= `id -u`
      end

      def user_id
        @user_id ||= `id -g`
      end

      def sync_user_with_host
        container.exec(['addgroup', '--gid', group_id, user_name])

        container.exec(['adduser',
          '--uid', user_id,
          '--gid', group_id,
          '--shell', '/bin/bash',
          '--home', ROOT_IN_CONTAINER,
          '--gecos', '',
          '--disabled-password',
          user_name])

        container.exec(['chown', '-R', "#{user_name}:#{user_name}", ROOT_IN_CONTAINER])
      end
  
      def stop_container
        # container.stop
        container.remove(force: true)
      end
    end
  end
end
