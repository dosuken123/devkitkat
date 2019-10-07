
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "devkitkat/version"

Gem::Specification.new do |spec|
  spec.name          = "devkitkat"
  spec.version       = Devkitkat::VERSION
  spec.authors       = ["Shinya Maeda"]
  spec.email         = ["shinya@gitlab.com"]

  spec.summary       = "Make micro services easy"
  spec.description   = "Make micro services easy"
  spec.homepage      = "https://gitlab.com/dosuken123/devkitkat"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = "devkitkat"
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-temp_dir", "~> 1.1.0"
  spec.add_development_dependency "pry", "~> 0.12.2"
  spec.add_development_dependency "pry-nav"
  spec.add_runtime_dependency "activesupport", "~> 6.0.0"
  spec.add_runtime_dependency "parallel", "~> 1.17.0"
  spec.add_runtime_dependency "ruby-progressbar", "~> 1.10.1"
  spec.add_runtime_dependency "colorize", "~> 0.8.1"
  spec.add_runtime_dependency "docker-api", "~> 1.34.2"
end
