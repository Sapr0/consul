#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_watch
default_action :create
unified_mode true

property :path,  String, default: lazy { join_path node['consul']['service']['config_dir'], "#{name}.json" }
property :user,  String, default: lazy { node['consul']['service_user'] }
property :group, String, default: lazy { node['consul']['service_group'] }
property :type,  String, equal_to: %w(checks event key keyprefix nodes service services)
property :parameters, Hash, default: {}

action :create do
  directory ::File.dirname(new_resource.path) do
    recursive true
    unless platform?('windows')
      owner new_resource.user
      group new_resource.group
      mode '0755'
    end
  end

  file new_resource.path do
    content new_resource.params_to_json
    unless platform?('windows')
      owner new_resource.user
      group new_resource.group
      mode '0640'
    end
  end
end

action(:delete) do
  file new_resource.path do
    action :delete
  end
end

action_class do
  def params_to_json
    JSON.pretty_generate(watches: [{ type: new_resource.type }.merge(new_resource.parameters)])
  end
end
