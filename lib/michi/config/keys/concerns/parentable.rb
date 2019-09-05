require 'active_support/concern'

module Michi
  class Config
    class Keys
      module Concerns
        module Parentable
          extend ActiveSupport::Concern

          included do
            attr_reader :children
            @wildcard = false
          end

          def has_children(children)
            @children = children
          end

          def self.parent_options
            yield
          end

          def self.wildcard
            @wildcard = true
          end
        end
      end
    end
  end
end
