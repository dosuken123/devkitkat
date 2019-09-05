module Michi
  class Config
    class Keys
      class Environment
        include Keys::Concerns::Keyable
        include Keys::Concerns::Parentable
      end
    end
  end
end
