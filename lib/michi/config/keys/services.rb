module Michi
  class Config
    class Keys
      class Services
        include Keys::Concerns::Keyable
        include Keys::Concerns::Parentable

        parent_options do
          wildcard
        end
      end
    end
  end
end
