module Michi
  class Config
    class Keys
      class Global
        include Keys::Concerns::Keyable
        include Keys::Concerns::Parentable
      end
    end
  end
end
