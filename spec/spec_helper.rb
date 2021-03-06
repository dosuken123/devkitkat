require "bundler/setup"
require "devkitkat"
require 'rspec/temp_dir'
require 'pry'
require_relative 'shared_examples'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    `docker rm -f $(docker ps -a -f name=devkitkat-test-* -q)`
  end
end

def in_tmp_dir(devkitkat_yml_path)
  cur_dir = Dir.pwd
  Dir.mktmpdir do |dir|
    FileUtils.copy(devkitkat_yml_path, File.join(dir, '.devkitkat.yml'))
    Dir.chdir dir
    yield dir
  end
ensure
  Dir.chdir cur_dir
end

def execute_devkitkat(cmd, ignore_termination: true)
  if ignore_termination
    allow_any_instance_of(Devkitkat::Processor).to receive(:terminate_process_group!)
  end

  ARGV.replace cmd
  Devkitkat::Main.execute
end
