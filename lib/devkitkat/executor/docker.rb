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
        puts "#{self.class.name} : #{__method__} : 1"
        pull_image unless image_exist?
        puts "#{self.class.name} : #{__method__} : 2"
        start_container
        puts "#{self.class.name} : #{__method__} : 3"
        sync_user_with_host
        puts "#{self.class.name} : #{__method__} : 4"
      end

      def cleanup
        puts "#{self.class.name} : #{__method__} : 5"
        stop_container
        puts "#{self.class.name} : #{__method__} : 6"
      end

      def commit(script_file)
        @script_file = script_file

        rewrite_root_path!
        new_path = script_path_in_container

        puts "#{self.class.name} : #{__method__} : 2"
        container.exec([new_path], user: user_name).tap do
          puts "#{self.class.name} : #{__method__} : 1"
        end
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

      def image_exist?
        ::Docker::Image.get(docker_image)
      rescue Docker::Error::NotFoundError
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
          '--home', root_in_container,
          '--gecos', '',
          '--disabled-password',
          user_name])

        container.exec(['chown', '-R', "#{user_name}:#{user_name}", root_in_container])
      end
  
      def stop_container
        # container.stop
        container.remove(force: true)
      end
    end
  end
end
