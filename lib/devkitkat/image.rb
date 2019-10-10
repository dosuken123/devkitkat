module Devkitkat
  class Image
    IMAGE_PREFIX = 'devkitkat'

    attr_reader :base, :install

    def initialize(base, install)
      @base, @install = base, install
    end

    def name
      # "#{IMAGE_PREFIX}-#{base_image}:#{install_checksum}"
      base
    end

    def regstry_url
      'dockerhub'
    end

    def build
      # TODO:
    end

    def push
      # TODO:
    end

    private

    def install_checksum
    end

    def base_image
      config.image
    end
  end
end
