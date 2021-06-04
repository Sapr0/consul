#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_definition
default_action :create
unified_mode true

property :path,       String, default: lazy { join_path node['consul']['service']['config_dir'], "#{name}.json" }
property :user,       String, default: lazy { node['consul']['service_user'] }
property :group,      String, default: lazy { node['consul']['service_group'] }
property :mode,       String, default: '0640'
property :type,       String, equal_to: %w(check service checks services)
property :parameters, Hash, default: {}

action :create do
  directory ::File.dirname(new_resource.path) do
    recursive true
    unless platform?('windows')
      owner new_resource.user
      group new_resource.group
      mode '0755'
      # Prevent clobbering permissions on the directory since the intent
      # in this context is to set the permissions of the definition file
      not_if { ::Dir.exist?(new_resource.path) }
    end
  end

  file new_resource.path do
    content params_to_json
    unless platform?('windows')
      owner new_resource.user
      group new_resource.group
      mode new_resource.mode
    end
  end
end

action :delete do
  file new_resource.path do
    action :delete
  end
end

action_class do
  include ConsulCookbook::Helpers

  def params_to_json
    final_parameters = new_resource.parameters
    final_parameters = final_parameters.merge(name: new_resource.name) if %w(check service).include?(new_resource.type) && final_parameters[:name].nil?
    JSON.pretty_generate(new_resource.type => final_parameters)
  end
end
