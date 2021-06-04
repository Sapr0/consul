#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_installation, provider: 'package'
default_action :create
unified_mode true

property :package_name,     String, default: ''
property :package_source,   String, default: ''
property :package_provider, String, default: ''

action :create do
  package new_resource.package_name do
    source new_resource.package_source
    provider new_resource.package_provider
    version new_resource.version
    action :upgrade
  end
end

action :remove do
  package new_resource.package_name do
    source new_resource.package_source
    provider new_resource.package_provider
    version new_resource.version
    action :remove
  end
end
