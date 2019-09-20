require "bundler/setup"
require "michi"
require 'rspec/temp_dir'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def in_tmp_dir(michi_yml_path)
  cur_dir = Dir.pwd
  Dir.mktmpdir do |dir|
    FileUtils.copy(michi_yml_path, File.join(dir, '.michi.yml'))
    Dir.chdir dir
    yield
  end
ensure
  Dir.chdir cur_dir
end

def execute_michi(cmd)
  ARGV.replace cmd
  Michi::Command.new.execute
end
