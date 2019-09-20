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

          expect(File.exist?('services/rails/script/configure'))
          expect(File.exist?('services/rails/script/unconfigure'))
          expect(File.exist?('services/rails/script/start'))
          expect(File.exist?('services/rails/script/stop'))
        end
      end

      it 'creates a script file when an arg is passed' do
        in_tmp_dir(sample_yml) do
          execute_michi(%w[add-script rails test])

          expect(File.exist?('services/rails/script/test'))
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

      it 'poops when system is specified' do
        in_tmp_dir(sample_yml) do
          expect_any_instance_of(Michi::Service).to receive(:poop) {}

          execute_michi(%w[poop system])
        end
      end
    end
  end
end
