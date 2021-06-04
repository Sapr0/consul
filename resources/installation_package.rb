#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_package_installation
default_action :create
unified_mode true

property :version,          String, name_property: true
property :package_name,     String
property :package_source,   String
property :package_provider, String

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
