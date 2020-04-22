# encoding: UTF-8

RSpec.describe Devkitkat do
  context 'with docker.devkitkat.yml', slow: true do
    let(:sample_yml) { 'spec/fixtures/docker.devkitkat.yml' }
    let(:root_dir) { Devkitkat::Service::Driver::Docker::Container::ROOT_IN_CONTAINER }

    it_behaves_like 'service execution'
  end
end
