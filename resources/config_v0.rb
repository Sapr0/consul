#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_config do
  node['consul']['version'].to_i < 1
end
default_action :create
unified_mode true

property :path,                            String, name_property: true
property :owner,                           String, default: lazy { node['consul']['service_user'] }
property :group,                           String, default: lazy { node['consul']['service_group'] }
property :config_dir,                      String, default: lazy { node['consul']['service']['config_dir'] }
property :config_dir_mode,                 String, default: '0755'
property :options,                         Hash,   default: {}
# http://www.consul.io/docs/agent/options.html
property :acl_agent_token,                 String, default: ''
property :acl_agent_master_token,          String, default: ''
property :acl_datacenter,                  String, default: ''
property :acl_default_policy,              String, default: ''
property :acl_down_policy,                 String, default: ''
property :acl_enforce_version_8,           [true, false]
property :acl_master_token,                String, default: ''
property :acl_replication_token,           String, default: ''
property :acl_token,                       String, default: ''
property :acl_ttl,                         String, default: ''
property :addresses,                       Hash,   default: {}
property :advertise_addr,                  String, default: ''
property :advertise_addr_wan,              String, default: ''
property :atlas_acl_token,                 String, default: ''
property :atlas_infrastructure,            String, default: ''
property :atlas_join,                      [true, false]
property :atlas_token,                     String, default: ''
property :atlas_endpoint,                  String, default: ''
property :autopilot,                       Hash,   default: {}
property :bind_addr,                       String, default: ''
property :bootstrap,                       [true, false]
property :bootstrap_expect,                Integer
property :ca_file,                         String, default: ''
property :ca_path,                         String, default: ''
property :cert_file,                       String, default: ''
property :check_update_interval,           String, default: ''
property :client_addr,                     String, default: ''
property :data_dir,                        String, default: ''
property :datacenter,                      String, default: ''
property :disable_anonymous_signature,     [true, false]
property :disable_host_node_id,            [true, false]
property :disable_keyring_file,            [true, false]
property :disable_remote_exec,             [true, false]
property :disable_update_check,            [true, false]
property :discard_check_output,            [true, false]
# Not supported, but allow same attribute for v0.x and 1.0.6+
property :discovery_max_stale,             String, default: ''
property :dns_config,                      Hash,   default: {}
property :domain,                          String, default: ''
property :enable_acl_replication,          [true, false]
property :enable_debug,                    [true, false]
property :enable_script_checks,            [true, false]
property :enable_syslog,                   [true, false]
property :encrypt,                         String, default: ''
property :encrypt_verify_incoming,         [true, false]
property :encrypt_verify_outgoing,         [true, false]
property :http_api_response_headers,       Hash,   default: {}
property :http_config,                     Hash,   default: {}
property :key_file,                        String, default: ''
property :leave_on_terminate,              [true, false]
property :limits,                          Hash,   default: {}
property :log_level,                       String, equal_to: %w(INFO DEBUG WARN ERR)
property :node_id,                         String, default: ''
property :node_name,                       String, default: ''
property :node_meta,                       Hash,   default: {}
property :non_voting_server,               [true, false]
property :performance,                     Hash,   default: {}
property :ports,                           Hash,   default: {}
property :protocol,                        String, default: ''
property :raft_protocol,                   Integer
property :reap,                            [true, false]
property :reconnect_timeout,               String, default: ''
property :reconnect_timeout_wan,           String, default: ''
property :recursor,                        String, default: ''
property :recursors,                       Array,  default: []
property :retry_interval,                  String, default: ''
property :retry_interval_wan,              String, default: ''
property :retry_join,                      Array,  default: []
property :retry_join_azure,                Hash,   default: {}
property :retry_join_ec2,                  Hash,   default: {}
property :retry_join_wan,                  Array,  default: []
property :retry_max,                       Integer
property :rejoin_after_leave,              [true, false]
property :segment,                         String, default: ''
property :segments,                        Array,  default: []
property :serf_lan_bind,                   String, default: ''
property :serf_wan_bind,                   String, default: ''
property :server,                          [true, false]
property :server_name,                     String, default: ''
property :session_ttl_min,                 String, default: ''
property :skip_leave_on_interrupt,         [true, false]
property :start_join,                      Array,  default: []
property :start_join_wan,                  Array,  default: []
property :statsd_addr,                     String, default: ''
property :statsite_addr,                   String, default: ''
property :statsite_prefix,                 String, default: ''
property :syslog_facility,                 String, default: ''
property :telemetry,                       Hash,   default: {}
property :tls_cipher_suites,               String, default: ''
property :tls_min_version,                 String, equal_to: %w(tls10 tls11 tls12)
property :tls_prefer_server_cipher_suites, [true, false]
property :translate_wan_addrs,             [true, false]
property :ui,                              [true, false]
property :ui_dir,                          String, default: ''
property :unix_sockets,                    Hash,   default: {}
property :verify_incoming,                 [true, false]
property :verify_incoming_https,           [true, false]
property :verify_incoming_rpc,             [true, false]
property :verify_outgoing,                 [true, false]
property :verify_server_hostname,          [true, false]
property :watches,                         Hash, default: {}

action :create do
  [::File.dirname(new_resource.path), new_resource.config_dir].each do |dir|
    directory dir do
      recursive true
      unless platform?('windows')
        owner new_resource.owner
        group new_resource.group
        mode new_resource.config_dir_mode
      end
      not_if { dir == '/etc' }
    end
  end

  file new_resource.path do
    unless platform?('windows')
      owner new_resource.owner
      group new_resource.group
      mode '0640'
    end
    content params_to_json
    sensitive true
  end
end

action :delete do
  file new_resource.path do
    action :delete
  end
end

action_class do
  include ConsulCookbook::Helpers

  # Transforms the resource into a JSON format which matches the
  # Consul service's configuration format.
  def params_to_json
    for_keeps = %i(
      acl_agent_token
      acl_agent_master_token
      acl_datacenter
      acl_default_policy
      acl_down_policy
      acl_enforce_version_8
      acl_master_token
      acl_replication_token
      acl_token
      acl_ttl
      addresses
      advertise_addr
      advertise_addr_wan
      atlas_acl_token
      atlas_endpoint
      atlas_infrastructure
      atlas_join
      atlas_token
      autopilot
      bind_addr
      check_update_interval
      client_addr
      data_dir
      datacenter
      disable_anonymous_signature
      disable_host_node_id
      disable_keyring_file
      disable_remote_exec
      disable_update_check
      discard_check_output
      dns_config
      domain
      enable_acl_replication
      enable_debug
      enable_script_checks
      enable_syslog
      encrypt
      encrypt_verify_incoming
      encrypt_verify_outgoing
      http_api_response_headers
      http_config
      leave_on_terminate
      limits
      log_level
      node_id
      node_meta
      non_voting_server
      node_name
      performance
      ports
      protocol
      reap
      raft_protocol
      reconnect_timeout
      reconnect_timeout_wan
      recursor
      recursors
      rejoin_after_leave
      retry_interval
      retry_interval_wan
      retry_join
      retry_join_azure
      retry_join_ec2
      retry_join_wan
      retry_max
      segment
      segments
      serf_lan_bind
      serf_wan_bind
      server
      server_name
      session_ttl_min
      skip_leave_on_interrupt
      start_join
      start_join_wan
      statsd_addr
      statsite_addr
      statsite_prefix
      syslog_facility
      telemetry
      tls_cipher_suites
      tls_min_version
      tls_prefer_server_cipher_suites
      translate_wan_addrs
      ui
      ui_dir
      unix_sockets
      verify_incoming
      verify_incoming_https
      verify_incoming_rpc
      verify_outgoing
      verify_server_hostname
      watches
    )

    for_keeps << %i(bootstrap bootstrap_expect) if new_resource.server
    for_keeps << %i(ca_file ca_path cert_file key_file) if tls?
    for_keeps = for_keeps.flatten

    # Filter out undefined attributes and keep only those listed above
    config = to_hash.keep_if do |k, v|
      !v.nil? && for_keeps.include?(k.to_sym)
    end.merge(new_resource.options)
    JSON.pretty_generate(Hash[config.sort_by { |k, _| k.to_s }], quirks_mode: true)
  end

  def tls?
    new_resource.verify_incoming || new_resource.verify_incoming_https || new_resource.verify_incoming_rpc || new_resource.verify_outgoing
  end
end
