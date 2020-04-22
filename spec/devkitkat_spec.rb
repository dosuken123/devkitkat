# encoding: UTF-8

RSpec.describe Devkitkat do
  it "has a version number" do
    expect(Devkitkat::VERSION).not_to be nil
  end

  # context 'with local.devkitkat.yml' do
  #   let(:sample_yml) { 'spec/fixtures/local.devkitkat.yml' }

  #   it_behaves_like 'service execution'
  # end

  context 'with docker.devkitkat.yml', slow: true do
    let(:sample_yml) { 'spec/fixtures/docker.devkitkat.yml' }
    let(:root_dir) { Devkitkat::Service::Driver::Docker::ROOT_IN_CONTAINER }

    it_behaves_like 'service execution'
  end
end
