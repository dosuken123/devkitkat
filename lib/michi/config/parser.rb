require 'yaml'

module Michi
  class Config
    class Parser
      def self.parse(path)
        raise 'File is not found' unless File.exist?(path)

        YAML.load_file(path)
      end
    end
  end
end
