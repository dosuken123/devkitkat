require 'active_support/core_ext/module/delegation'

module Devkitkat
  class Service
    module Concerns
      module ServiceInitializer
        attr_reader :service

        delegate :config, :command, to: :service

        def initialize(service)
          @service = service
        end
      end
    end
  end
end
