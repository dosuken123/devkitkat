# encoding: UTF-8

RSpec.describe Devkitkat do
  context 'with local.devkitkat.yml' do
    let(:sample_yml) { 'spec/fixtures/local.devkitkat.yml' }

    it_behaves_like 'service execution'
  end
end
