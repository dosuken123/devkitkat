module Devkitkat
  class Service
    class Driver
      class Docker < Base
        class Image
          include Concerns::ServiceInitializer

          def pull
            image_exist? || pull_image
          end

          private

          def pull_image
            puts "Pulling image #{image}..."
            ::Docker::Image.create('fromImage' => image)
            puts "Pulled image #{image}..."
          end

          def image_exist?
            ::Docker::Image.get(image)
          rescue
            false
          end

          def image
            config.machine_image
          end
        end
      end
    end
  end
end
