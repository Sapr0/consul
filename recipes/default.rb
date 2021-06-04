#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
group node['consul']['service_group'] do
  not_if { windows? }
  not_if { node['consul']['service_user'] == 'root' }
  not_if { node['consul']['create_service_user'] == false }
end

user node['consul']['service_user'] do
  comment "Service user for #{node['consul']['service_name']}"
  group node['consul']['service_group']
  shell node['consul']['service_shell'] unless node['consul']['service_shell'].nil?
  not_if { windows? }
  not_if { node['consul']['service_user'] == 'root' }
  not_if { node['consul']['create_service_user'] == false }
end

service_name = node['consul']['service_name']
consul_config service_name do |r|
  node['consul']['config'].each_pair { |k, v| r.send(k, v) }
  notifies :reload, "consul_service[#{service_name}]", :delayed
end

consul_installation node['consul']['version'] do |r|
  if node['consul']['installation']
    node['consul']['installation'].each_pair { |k, v| r.send(k, v) }
  end
end

consul_service service_name do |r|
  if node['consul']['service']
    node['consul']['service'].each_pair { |k, v| r.send(k, v) }
  end
end
