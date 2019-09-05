require 'active_support/inflector'
require "michi/config/keys/application"
require "michi/config/keys/version"
require "michi/config/keys/global"

module Michi
  class Config
    class Keys
      KeyNotFoundError = Class.new(StandardError)

      def initialize(hash)
        hash.map do |key, value|
          klass = "#{self.class.name}::#{key.classify}".safe_constantize

          unless klass
            raise KeyNotFoundError, "The key \"#{key}\" is not supported"
          end

          klass.new(value)
        end
      end
    end
  end
end
