module Michi
  class Config
    class Keys
      class Base
        attr_reader :value

        def initialize(value)
          @value = value
        end
      end
    end
  end
end
