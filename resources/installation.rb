#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_installation
default_action :create
unified_mode true

property :version, String, name_property: true
property :provider, String, equals_to: %w(binary git package), default: 'binary'
