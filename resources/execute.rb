#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_execute
default_action :run
unified_mode true

property :command,     String, name_property: true
property :environment, Hash,   default: { 'PATH' => '/usr/local/bin:/usr/bin:/bin' }
property :options,     Hash,   default: {}

action :run do
  options = new_resource.options.map do |k, v|
    next if v.is_a?(NilClass) || v.is_a?(FalseClass)
    if v.is_a?(TrueClass)
      "-#{k}"
    else
      ["-#{k}", v].join('=')
    end
  end

  command = ['/usr/bin/env consul exec', options, new_resource.command].flatten.compact
  execute command.join(' ') do
    environment new_resource.environment
  end
end
