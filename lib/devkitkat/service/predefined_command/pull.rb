module Devkitkat
  class Service
    class PredefinedCommand
      class Pull < Base
        def to_script
          <<~EOS
            cd #{service.src_dir}
            git checkout master
            git pull origin master
          EOS
        end

        def available?
          service.repo_defined?
        end

        def machine_driver
          'none'
        end
      end
    end
  end
end
