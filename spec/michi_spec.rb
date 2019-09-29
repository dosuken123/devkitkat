# encoding: UTF-8

RSpec.describe Michi do
  it "has a version number" do
    expect(Michi::VERSION).not_to be nil
  end

  let(:long_script) do
    <<-EOS
#!/bin/bash
sleep 2s
    EOS
  end

  let(:failed_script) do
    <<-EOS
#!/bin/bash
exit 1
    EOS
  end

  let(:export_script) do
    <<-EOS
#!/bin/bash
export
    EOS
  end

  let(:shared_script) do
    <<-EOS
#!/bin/bash

test()
{
    echo "This is test"
}
    EOS
  end

  let(:function_script) do
    <<-EOS
#!/bin/bash
source ${MI_SYSTEM_SHARED_SCRIPT_DIR}

test
    EOS
  end

  context 'with local.michi.yml' do
    let(:sample_yml) { 'spec/fixtures/local.michi.yml' }

    context 'when executes add-script' do
      it 'creates default files when no arguments' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[add-script rails])

          expect(File.exist?('services/rails/script/configure')).to eq(true)
          expect(File.exist?('services/rails/script/unconfigure')).to eq(true)
          expect(File.exist?('services/rails/script/start')).to eq(true)
          expect(File.exist?('services/rails/script/stop')).to eq(true)
        end
      end

      it 'creates a script file when an arg is passed' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[add-script rails test])

          expect(File.exist?('services/rails/script/test')).to eq(true)
        end
      end

      it 'creates a script file when target is system' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[add-script system local-setup])

          expect(File.exist?('services/system/script/local-setup')).to eq(true)
        end
      end

      context 'when a script already exists' do
        it 'does not overwrite the script' do
          in_tmp_dir(sample_yml) do
            FileUtils.mkdir_p('services/rails/script')
            FileUtils.touch('services/rails/script/test')

            execute_michi(%w[add-script rails test])

            expect(File.read('services/rails/script/test')).to be_empty
          end
        end
      end

      context 'when targets the data group' do
        it 'executes a script to the services in the data group' do
          in_tmp_dir(sample_yml) do
            execute_michi(%w[add-script data test])

            expect(File.exist?('services/postgres/script/test')).to eq(true)
            expect(File.exist?('services/redis/script/test')).to eq(true)
            expect(File.exist?('services/rails/script/test')).to eq(false)
          end
        end

        context 'when excludes the redis service' do
          it 'executes a script to the services in the data group' do
            in_tmp_dir(sample_yml) do
              execute_michi(%w[add-script data test --exclude redis])

              expect(File.exist?('services/postgres/script/test')).to eq(true)
              expect(File.exist?('services/redis/script/test')).to eq(false)
              expect(File.exist?('services/rails/script/test')).to eq(false)
            end
          end
        end
      end

      context 'when multiple arguments are passed' do
        it 'adds multiple scripts' do
          in_tmp_dir(sample_yml) do
            execute_michi(%w[add-script rails test check])

            expect(File.exist?('services/rails/script/test')).to eq(true)
            expect(File.exist?('services/rails/script/check')).to eq(true)
          end
        end
      end
    end

    context 'when executes add-example' do
      context 'when multiple arguments are passed' do
        it 'adds multiple scripts' do
          in_tmp_dir(sample_yml) do
            execute_michi(%w[add-example rails application.config.example database.config.example])

            expect(File.exist?('services/rails/example/application.config.example')).to eq(true)
            expect(File.exist?('services/rails/example/database.config.example')).to eq(true)
          end
        end
      end
    end

    context 'when executes add-shared-script' do
      it 'adds shared scripts' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[add-shared-script])
          File.write('services/system/script/shared', shared_script)
          execute_michi(%w[add-script rails test])
          File.write('services/rails/script/test', function_script)
          execute_michi(%w[test rails])
          expect(File.read('services/rails/log/test.log')).to match(/This is test/)
        end
      end
    end

    context 'when executes poop' do
      it 'poops when no target is specified' do
        in_tmp_dir(sample_yml) do
          expect_any_instance_of(Michi::Service).to receive(:poop) {}

          execute_michi(%w[poop])
        end
      end

      it 'logs that a predefined script is executed' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[poop])

          expect(File.read('services/system/log/poop.log'))
            .to match(/This script is a predefined script provided by michi./)
          expect(File.read('services/system/log/poop.log')).to match(/💩/)
        end
      end

      it 'poops when system is specified' do
        in_tmp_dir(sample_yml) do
          expect_any_instance_of(Michi::Service).to receive(:poop) {}

          execute_michi(%w[poop system])
        end
      end
    end

    context 'when executes clone' do
      it 'clones a repository', slow: true do
        in_tmp_dir(sample_yml) do |dir|
          execute_michi(%w[clone rails --depth 1])

          expect(File.read('services/rails/src/.git/config'))
            .to include("url = https://github.com/dosuken123/michi-example-rails.git")
        end
      end
    end

    context 'when executes reconfigure' do
      context 'when export all variables' do
        it 'prints correct variables' do
          in_tmp_dir(sample_yml) do |dir|
            execute_michi(%w[add-script rails])
            File.write('services/rails/script/configure', export_script)
            execute_michi(%w[reconfigure rails])

            expect(File.read('services/rails/log/reconfigure.log'))
              .to match(%r{MI_SELF_DIR=.*#{dir}/services/rails.*})
          end
        end

        context 'when targets group' do
          it 'prints correct variables' do
            in_tmp_dir(sample_yml) do |dir|
              execute_michi(%w[add-script data])
              File.write('services/postgres/script/configure', export_script)
              File.write('services/redis/script/configure', export_script)
              execute_michi(%w[reconfigure data])

              expect(File.read('services/postgres/log/reconfigure.log'))
                .to match(%r{MI_SELF_DIR=.*#{dir}/services/postgres.*})
              expect(File.read('services/postgres/log/reconfigure.log'))
                .to match(%r{MI_REDIS_PORT=.*6379.*})
              expect(File.read('services/redis/log/reconfigure.log'))
                .to match(%r{MI_SELF_DIR=.*#{dir}/services/redis.*})
              expect(File.read('services/redis/log/reconfigure.log'))
                .to match(%r{MI_POSTGRES_PORT=.*5432.*})
            end
          end
        end
      end

      context 'when configure/unconfigure scripts do not exist' do
        it 'raises an error' do
          in_tmp_dir(sample_yml) do |dir|
            expect { execute_michi(%w[reconfigure rails]) }
              .to raise_error(Parallel::Kill)
          end
        end
      end
    end

    context 'when executes a custom script' do
      it 'logs that a custom script is executed' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[add-script rails test])
          execute_michi(%w[test rails])

          expect(File.read('services/rails/log/test.log'))
            .to match(/This script is a custom script provided by you./)
        end
      end

      context 'when targets group' do
        context 'when one of the scripts failed' do
          it 'performs fast fail' do
            in_tmp_dir(sample_yml) do |dir|
              execute_michi(%w[add-script data test])
              File.write('services/postgres/script/test', long_script)
              File.write('services/redis/script/test', failed_script)
              start = Time.now
              execute_michi(%w[test data])
              diff = Time.now - start

              expect(diff).to be < 1
            end
          end
        end
      end

      context 'when targets system' do
        it 'executes a script without specifying target' do
          in_tmp_dir(sample_yml) do
            execute_michi(%w[add-script system local-setup])
            expect { execute_michi(%w[local-setup]) }.not_to raise_error
          end
        end
      end

      context 'when export all variables' do
        it 'prints correct variables' do
          in_tmp_dir(sample_yml) do |dir|
            execute_michi(%w[add-script rails configure])
            File.write('services/rails/script/configure', export_script)
            execute_michi(%w[configure rails])

            expect(File.read('services/rails/log/configure.log'))
              .to match(%r{MI_SELF_DIR=.*#{dir}/services/rails.*})
          end
        end
      end
    end
  end

  context 'with docker.michi.yml' do
    let(:sample_yml) { 'spec/fixtures/docker.michi.yml' }

    context 'when executes poop' do
      it 'executes the script in a container' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[poop])

          expect(File.read('services/system/log/poop.log'))
            .to match(/This script is a predefined script provided by michi./)
          expect(File.read('services/system/log/poop.log')).to match(/💩/)
        end
      end
    end
  end
end
