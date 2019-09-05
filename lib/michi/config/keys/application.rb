require "michi/config/keys/concerns/keyable"

module Michi
  class Config
    class Keys
      class Application
        include Keys::Concerns::Keyable
      end
    end
  end
end