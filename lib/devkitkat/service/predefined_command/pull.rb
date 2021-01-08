module Devkitkat
  class Service
    class PredefinedCommand
      class Pull < Base
        DEFAULT_REPO_REF = 'master'.freeze

        def to_script
          <<~EOS
            cd #{service.src_dir}
            git checkout #{repo_ref}
            git pull origin #{repo_ref}
          EOS
        end

        def repo_ref
          service.repo_ref || DEFAULT_REPO_REF
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
