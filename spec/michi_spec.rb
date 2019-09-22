RSpec.describe Michi do
  it "has a version number" do
    expect(Michi::VERSION).not_to be nil
  end

  context 'with sample.michi.yml' do
    let(:sample_yml) { 'spec/fixtures/sample.michi.yml' }

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

    context 'when executes reconfigure' do
      context 'when export all variables' do
        let(:export_script) do
          <<-EOS
  #!/bin/bash
  export
          EOS
        end

        it 'prints correct variables' do
          in_tmp_dir(sample_yml) do |dir|
            execute_michi(%w[add-script rails])
            File.write('services/rails/script/configure', export_script)
            execute_michi(%w[reconfigure rails])

            expect(File.read('services/rails/log/reconfigure.log'))
              .to include(%Q{MI_SELF_DIR="#{dir}/services/rails"})
          end
        end
      end

      context 'when configure/unconfigure scripts do not exist' do

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

      context 'when targets system' do
        it 'executes a script without specifying target' do
          in_tmp_dir(sample_yml) do
            execute_michi(%w[add-script system local-setup])
            expect { execute_michi(%w[local-setup]) }.not_to raise_error
          end
        end
      end

      context 'when export all variables' do
        let(:export_script) do
          <<-EOS
  #!/bin/bash
  export
          EOS
        end

        it 'prints correct variables' do
          in_tmp_dir(sample_yml) do |dir|
            execute_michi(%w[add-script rails configure])
            File.write('services/rails/script/configure', export_script)
            execute_michi(%w[configure rails])

            expect(File.read('services/rails/log/configure.log'))
              .to include(%Q{MI_SELF_DIR="#{dir}/services/rails"})
          end
        end
      end
    end
  end
end
