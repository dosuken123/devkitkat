module Devkitkat
  class Service
    class Driver
      class Docker < Base
        class Container
          include Concerns::ServiceInitializer

          ROOT_IN_CONTAINER = '/devkitkat'

          attr_reader :container

          def start
            if @container = find
              container.start
            else
              @container = create
              container.start
              create_host_user
            end
          end

          def stop
            raise 'Container has not started yet' unless container

            container.stop
          end

          def exec(cmds, params = {})
            params.merge!(user: user_name)
            safe_exec(cmds, params)
          end

          def exec_as_host(cmds, params = {})
            safe_exec(cmds, params)
          end

          private

          def safe_exec(cmds, params)
            params.merge!(wait: 604800) # Default timeout is 1 minute, so setting 1 week instead
            stdout_messages, stderr_messages, exit_code =
              container.exec(cmds, params)

            if exit_code != 0 || command.debug?
              puts "#{self.class.name} - #{__callee__}: stdout_messages: #{stdout_messages} stderr_messages: #{stderr_messages} exit_code: #{exit_code}"
            end

            exit_code == 0 ? true : false
          rescue ::Docker::Error::ConflictError => e
            puts "#{self.class.name} - #{__callee__}: #{e.message}"
            false
          end

          def image
            config.machine_image
          end

          def name
            @name ||=
              "#{config.application}-#{service.name}-#{Digest::SHA1.hexdigest(command.kit_root)[8..12]}"
          end

          def find
            ::Docker::Container.get(name)
          rescue ::Docker::Error::NotFoundError
            nil
          end

          def create
            ::Docker::Container.create(create_parameter)
          end

          def create_parameter
            params = {
              'Cmd' => %w[tail -f],
              'Image' => image,
              'name' => name,
              'HostConfig' => {
                'Binds' => all_mounts
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

            if config.machine_extra_hosts
              params.deep_merge!('HostConfig' => { 'ExtraHosts' => config.machine_extra_hosts })
            end

            if config.machine_network_mode
              params.deep_merge!('HostConfig' => { 'NetworkMode' => config.machine_network_mode })
            end

            params
          end

          def all_mounts
            config.all_services.map do |service_name|
              service = Service.new(service_name, config, command)

              FileUtils.mkdir_p(service.dir)

              if self.service.name == service_name || service.system? || allowed_by_extra_write_accesses?(service)
                "#{service.dir}:#{ROOT_IN_CONTAINER}/services/#{service.name}"
              else
                "#{service.dir}:#{ROOT_IN_CONTAINER}/services/#{service.name}:ro"
              end
            end
          end

          def allowed_by_extra_write_accesses?(service)
            config.extra_write_accesses&.any? do |access|
              from, _, to = access.split(':')
              self.service.name == from && service.name == to
            end
          end

          def user_name
            'devkitkat'
          end

          def group_id
            @group_id ||= `id -u`.delete("\n")
          end

          def user_id
            @user_id ||= `id -g`
          end

          def create_host_user
            prepare!(['addgroup', '--gid', group_id, user_name])

            prepare!(['adduser',
              '--uid', user_id,
              '--gid', group_id,
              '--shell', '/bin/bash',
              '--home', ROOT_IN_CONTAINER,
              '--gecos', '',
              '--disabled-password',
              user_name])

            prepare!(['chown', "#{user_name}:#{user_name}", ROOT_IN_CONTAINER])
            prepare!(['chown', '-R', "#{user_name}:#{user_name}", "#{ROOT_IN_CONTAINER}/services/#{service.name}"])
          end

          def prepare!(cmds, params = {})
            unless exec_as_host(cmds, params)
              raise Driver::Base::PreparationError, "Failed to execute command in container. cmds: #{cmds}"
            end
          end
        end
      end
    end
  end
end
