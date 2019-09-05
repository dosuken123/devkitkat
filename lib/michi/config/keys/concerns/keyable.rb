require 'active_support/concern'

module Michi
  class Config
    class Keys
      module Concerns
        module Keyable
          extend ActiveSupport::Concern

          included do
            attr_reader :value
          end

          def initialize(value)
            @value = value
          end
        end
      end
    end
  end
end
