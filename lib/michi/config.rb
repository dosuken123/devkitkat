require "michi/config"
require "michi/config/parser"
require "michi/config/keys"

module Michi
  class Config
    MICHI_YAML_FILE = '.michi.yml'

    attr_reader :keys

    def initialize
      load
    end

    def load
      hash = Parser.parse(config_path)
      @keys = Keys.new(hash)
    end

    def config_path
      File.join(Dir.pwd, MICHI_YAML_FILE)
    end
  end
end
