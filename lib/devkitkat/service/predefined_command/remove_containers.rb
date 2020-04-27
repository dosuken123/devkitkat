module Devkitkat
  class Service
    class PredefinedCommand
      class RemoveContainers < Base
        def to_script
          <<~EOS
            docker rm -f $(docker ps -a -f name=#{config.application}-* -q)
          EOS
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
