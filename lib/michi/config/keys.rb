require 'active_support/inflector'
require 'require_all'
require_all 'lib/michi/config/keys'

module Michi
  class Config
    class Keys
      KeyNotFoundError = Class.new(StandardError)

      attr_reader :keys

      def initialize(hash)
        @keys = dig(hash)
      end

      private

      def dig(hash, parent = nil)
        hash.map do |key, value|
          current = fabricate(key, value, parent)
          current.has_children(dig(value, key, current)) if value.is_a?(Hash)
        end
      end

      def fabricate(key, value, parent)
        klass = "#{self.class.name}::#{key.classify}".safe_constantize

        unless klass
          raise KeyNotFoundError, "The key \"#{key}\" is not supported"
        end

        klass.new(value)
      end
    end
  end
end
