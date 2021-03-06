shared_examples_for 'service execution' do
  let(:long_script) do
    <<-EOS
#!/bin/bash
set -e
sleep 30s
echo "Finished long task"
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
source ${DK_SYSTEM_SHARED_SCRIPT_PATH}

test
    EOS
  end

  context 'when executes help' do
    it 'shows help' do
      in_tmp_dir(sample_yml) do
        expect_any_instance_of(Devkitkat::Command)
          .to receive(:show_help).once

        execute_devkitkat(%w[help])
      end
    end
  end

  context 'when executes add-script' do
    it 'creates default files when no arguments' do
      in_tmp_dir(sample_yml) do
        execute_devkitkat(%w[add-script rails])

        expect(File.exist?('services/rails/script/configure')).to eq(true)
        expect(File.exist?('services/rails/script/unconfigure')).to eq(true)
        expect(File.exist?('services/rails/script/start')).to eq(true)
      end
    end

    it 'creates a script file when an arg is passed' do
      in_tmp_dir(sample_yml) do
        execute_devkitkat(%w[add-script rails test])

        expect(File.exist?('services/rails/script/test')).to eq(true)
      end
    end

    it 'creates a script file when target is system' do
      in_tmp_dir(sample_yml) do
        execute_devkitkat(%w[add-script system local-setup])

        expect(File.exist?('services/system/script/local-setup')).to eq(true)
      end
    end

    context 'when a script already exists' do
      it 'does not overwrite the script' do
        in_tmp_dir(sample_yml) do
          FileUtils.mkdir_p('services/rails/script')
          FileUtils.touch('services/rails/script/test')

          execute_devkitkat(%w[add-script rails test])

          expect(File.read('services/rails/script/test')).to be_empty
        end
      end
    end

    context 'when targets the data group' do
      it 'executes a script to the services in the data group' do
        in_tmp_dir(sample_yml) do
          execute_devkitkat(%w[add-script data test])

          expect(File.exist?('services/postgres/script/test')).to eq(true)
          expect(File.exist?('services/redis/script/test')).to eq(true)
          expect(File.exist?('services/rails/script/test')).to eq(false)
        end
      end

      context 'when excludes the redis service' do
        it 'executes a script to the services in the data group' do
          in_tmp_dir(sample_yml) do
            execute_devkitkat(%w[add-script data test --exclude redis])

            expect(File.exist?('services/postgres/script/test')).to eq(true)
            expect(File.exist?('services/redis/script/test')).to eq(false)
            expect(File.exist?('services/rails/script/test')).to eq(false)
          end
        end
      end

      context 'when specify targets with comma separted string' do
        it 'executes a script to the services' do
          in_tmp_dir(sample_yml) do
            execute_devkitkat(%w[add-script redis,rails test])

            expect(File.exist?('services/postgres/script/test')).to eq(false)
            expect(File.exist?('services/redis/script/test')).to eq(true)
            expect(File.exist?('services/rails/script/test')).to eq(true)
          end
        end
      end
    end

    context 'when multiple arguments are passed' do
      it 'adds multiple scripts' do
        in_tmp_dir(sample_yml) do
          execute_devkitkat(%w[add-script rails test check])

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
          execute_devkitkat(%w[add-example rails application.config.example database.config.example])

          expect(File.exist?('services/rails/example/application.config.example')).to eq(true)
          expect(File.exist?('services/rails/example/database.config.example')).to eq(true)
        end
      end
    end
  end

  context 'when executes add-shared-script' do
    it 'adds shared scripts' do
      in_tmp_dir(sample_yml) do
        execute_devkitkat(%w[add-shared-script])
        File.write('services/system/script/shared', shared_script)
        execute_devkitkat(%w[add-script rails test])
        File.write('services/rails/script/test', function_script)
        execute_devkitkat(%w[test rails])
        expect(File.read('services/rails/log/test.log')).to match(/This is test/)
      end
    end
  end

  context 'when executes poop' do
    it 'logs that a predefined script is executed' do
      in_tmp_dir(sample_yml) do
        execute_devkitkat(%w[poop])

        expect(File.read('services/system/log/poop.log'))
          .to match(/INFO: This script is a predefined script in devkitkat./)
        expect(File.read('services/system/log/poop.log')).to match(/💩/)
      end
    end

    context 'when root path is specified' do
      it 'executes correctly' do
        in_tmp_dir(sample_yml) do |dir|
          new_dir = "#{dir}/services/rails/src"
          FileUtils.mkdir_p(new_dir)
          Dir.chdir new_dir

          expect { execute_devkitkat(['--path', dir, 'poop']) }.not_to raise_error
        end
      end
    end
  end

  context 'when executes clone' do
    it 'clones a repository', slow: true do
      in_tmp_dir(sample_yml) do |dir|
        execute_devkitkat(%w[clone rails --env-var GIT_DEPTH=1])

        expect(File.read('services/rails/src/.git/config'))
          .to include("url = https://github.com/dosuken123/devkitkat-example-rails.git")
      end
    end
  end

  context 'when executes exec' do
    it 'executes the command in the src dir' do
      in_tmp_dir(sample_yml) do |dir|
        FileUtils.mkdir_p("#{dir}/services/rails/src")
        File.write("#{dir}/services/rails/src/test", 'This is a test file')
        execute_devkitkat(%w[exec rails cat test])

        expect(File.read('services/rails/log/exec.log'))
          .to include('This is a test file')
      end
    end
  end

  context 'when executes reconfigure' do
    context 'when export all variables' do
      it 'prints correct variables' do
        in_tmp_dir(sample_yml) do |dir|
          execute_devkitkat(%w[add-script rails])
          File.write('services/rails/script/configure', export_script)
          execute_devkitkat(%w[reconfigure rails])

          dir = root_dir if defined?(root_dir)

          expect(File.read('services/rails/log/reconfigure.log'))
            .to match(%r{DK_SELF_DIR=.*#{dir}/services/rails.*})
        end
      end

      context 'when targets group' do
        it 'prints correct variables' do
          in_tmp_dir(sample_yml) do |dir|
            execute_devkitkat(%w[add-script data])
            File.write('services/postgres/script/configure', export_script)
            File.write('services/redis/script/configure', export_script)
            execute_devkitkat(%w[reconfigure data])

            dir = root_dir if defined?(root_dir)

            expect(File.read('services/postgres/log/reconfigure.log'))
              .to match(%r{DK_SELF_DIR=.*#{dir}/services/postgres.*})
            expect(File.read('services/postgres/log/reconfigure.log'))
              .to match(%r{DK_REDIS_PORT=.*6379.*})
            expect(File.read('services/redis/log/reconfigure.log'))
              .to match(%r{DK_SELF_DIR=.*#{dir}/services/redis.*})
            expect(File.read('services/redis/log/reconfigure.log'))
              .to match(%r{DK_POSTGRES_PORT=.*5432.*})
          end
        end
      end
    end

    context 'when configure/unconfigure scripts do not exist' do
      it 'raises an error' do
        in_tmp_dir(sample_yml) do |dir|
          expect { execute_devkitkat(%w[reconfigure rails]) }
            .not_to raise_error
        end
      end
    end
  end

  context 'when executes a custom script' do
    it 'logs that a custom script is executed' do
      in_tmp_dir(sample_yml) do
        execute_devkitkat(%w[add-script rails test])
        execute_devkitkat(%w[test rails])

        expect(File.read('services/rails/log/test.log'))
          .to match(/INFO: This script is a custom script/)
      end
    end

    context 'when targets group' do
      context 'when one of the scripts failed' do
        it 'performs fast fail' do
          in_tmp_dir(sample_yml) do |dir|
            execute_devkitkat(%w[add-script data test])
            File.write('services/postgres/script/test', long_script)
            File.write('services/redis/script/test', failed_script)

            expect_any_instance_of(Devkitkat::Processor)
              .to receive(:terminate_process_group!)
            execute_devkitkat(%w[test data], ignore_termination: false)

            expect(File.read('services/postgres/log/test.log'))
              .not_to match(/Finished long task/)
          end
        end
      end
    end

    context 'when targets system' do
      it 'executes a script without specifying target' do
        in_tmp_dir(sample_yml) do
          execute_devkitkat(%w[add-script system local-setup])
          expect { execute_devkitkat(%w[local-setup]) }.not_to raise_error
        end
      end
    end

    context 'when export all variables' do
      it 'prints correct variables' do
        in_tmp_dir(sample_yml) do |dir|
          execute_devkitkat(%w[add-script rails configure])
          File.write('services/rails/script/configure', export_script)
          execute_devkitkat(%w[configure rails])

          dir = root_dir if defined?(root_dir)

          expect(File.read('services/rails/log/configure.log'))
            .to match(%r{DK_APPLICATION=.*devkitkat.*})
          expect(File.read('services/rails/log/configure.log'))
            .to match(%r{DK_SELF_DIR=.*#{dir}/services/rails.*})
          expect(File.read('services/rails/log/configure.log'))
            .to match(%r{RAILS_ENV=.*development.*})
          expect(File.read('services/rails/log/configure.log'))
            .to match(%r{GEM_PATH=.*#{dir}/services/rails/cache.*})
        end
      end

      context 'when --env-var option is passed' do
        it 'prints additional variables' do
          in_tmp_dir(sample_yml) do |dir|
            execute_devkitkat(%w[add-script rails configure])
            File.write('services/rails/script/configure', export_script)
            execute_devkitkat(%w[configure rails --env-var a_flag=true])

            expect(File.read('services/rails/log/configure.log'))
              .to match(%r{a_flag=.*true.*})
          end
        end
      end
    end
  end

  context 'when executes show-variables' do
    it 'prints correct variables' do
      in_tmp_dir(sample_yml) do |dir|
        execute_devkitkat(%w[show-variables rails])

        dir = root_dir if defined?(root_dir)

        expect(File.read('services/rails/log/show-variables.log'))
          .to match(%r{DK_APPLICATION=.*devkitkat.*})
        expect(File.read('services/rails/log/show-variables.log'))
          .to match(%r{DK_SELF_DIR=.*#{dir}/services/rails.*})
        expect(File.read('services/rails/log/show-variables.log'))
          .to match(%r{RAILS_ENV=.*development.*})
        expect(File.read('services/rails/log/show-variables.log'))
          .to match(%r{GEM_PATH=.*#{dir}/services/rails/cache.*})
      end
    end
  end
end
