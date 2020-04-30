module Devkitkat
  class Service
    class Executor
      class Variables
        include Concerns::ServiceInitializer

        def to_script
          [predefined_global_variables,
            predefined_service_variables,
            predefined_service_specific_variables,
            config_global_variables,
            config_service_variables,
            command_variables].flatten.join("\n")
        end

        private

        def predefined_global_variables
          variables = []
          variables << "export DK_ROOT_DIR=#{command.kit_root}"
          variables << "export DK_COMMAND_TARGET=#{command.target}"
          variables << "export DK_MACHINE_DRIVER=#{config.machine_driver.to_s}"
          variables << "export DK_MACHINE_LOCATION=#{config.machine_location.to_s}"
          variables << "export DK_MACHINE_IMAGE=#{config.machine_image.to_s}"
          variables << "export DK_MACHINE_EXTRA_HOSTS=#{config.machine_extra_hosts&.join(',').to_s}"
          variables << "export DK_MACHINE_NETWORK_MODE=#{config.machine_network_mode.to_s}"
          variables << "export DK_APPLICATION=#{config.application.to_s}"
          variables
        end
  
        def predefined_service_variables
          variables = []

          all_services.each do |service|
            variables << "export DK_#{service.name.upcase}_DIR=#{service.dir}"
  
            DIVISIONS.each do |division|
              variables << "export DK_#{service.name.upcase}_#{division.upcase}_DIR=#{service.send("#{division}_dir")}"
            end

            config.service_hash(service.name).each do |key, value|
              next if value.is_a?(Hash)

              variables << "export DK_#{service.name.upcase}_#{key.upcase}=#{value}"
            end

            if service.system?
              variables << "export DK_#{service.name.upcase}_SHARED_SCRIPT_PATH=#{service.shared_script_path}"
            end
          end

          variables
        end
  
        def predefined_service_specific_variables
          variables = []

          variables << "export DK_SELF_DIR=#{service.dir}"
  
          DIVISIONS.each do |division|
            variables << "export DK_SELF_#{division.upcase}_DIR=#{service.send("#{division}_dir")}"
          end

          variables
        end

        def config_global_variables
          config.variables.map { |key, value| "export #{key}=#{value}" }
        end

        def config_service_variables
          config.service_hash(service.name).map do |key, value|
            next if value.is_a?(Hash)

            "export #{key}=#{value}"
          end
        end

        def command_variables
          command.variables&.map { |key, value| "export #{key}=#{value}" }
        end

        def all_services
          @all_services ||= config.all_services.map { |service| Service.new(service, config, command) }
        end
      end
    end
  end
end
