#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_git_installation
default_action :create
unified_mode true

property :version,  String, name_property: true
property :git_url,  String, default: 'https://github.com/hashicorp/consul'
property :git_path, String, default: '/usr/local/go/src/github.com/hashicorp/consul'

action :create do
  include_recipe 'golang::default'
  golang_package 'github.com/mitchellh/gox'
  golang_package 'github.com/tools/godep'

  directory new_resource.git_path do
    recursive true
  end

  package 'zip' do
    action :install
  end

  git new_resource.git_path do
    repository new_resource.git_url
    revision new_resource.version
    action :checkout
  end

  execute 'make' do
    cwd new_resource.git_path
    environment(PATH: "#{node['go']['install_dir']}/go/bin:#{node['go']['gobin']}:/usr/bin:/bin",
                GOPATH: node['go']['gopath'])
  end
end

action :remove do
  directory new_resource.git_path do
    recursive true
    action :delete
  end
end
