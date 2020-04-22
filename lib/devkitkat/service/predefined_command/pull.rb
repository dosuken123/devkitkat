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
          repo_defined?
        end
      end
    end
  end
end
