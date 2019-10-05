require 'active_support/core_ext/module/delegation'

module Michi
  class Executor
    class Docker
      attr_reader :service

      delegate :config, :command, to: :service

      def initialize(service)
        @service = service
      end

      def prepare
        start_container
      end

      def cleanup
        stop_container
      end

      def exec(cmd)
        container.exec(cmd).tap do |ret|
          puts "#{self.class.name} : #{__method__} : ret: #{ret}"
        end
      end

      private
  
      def docker_image
        config.environment_image
      end
  
      def container
        @container ||= Docker::Container.create(
          'Cmd' => %w[tail -f],
          'Image' => docker_image,
          'name' => service.container_name
        )
      end
  
      # TODO: Rewrite in bash
  
      def start_container
        container.start
        # TODO: Initiate contianer. Mount source dir.
        container.exec(%w[date]).tap do |ret|
          puts "#{self.class.name} : #{__method__} : ret: #{ret}"
        end
      end
  
      def stop_container
        container.stop
        container.remove
      end
    end
  end
end
