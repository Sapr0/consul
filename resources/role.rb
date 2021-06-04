#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_role
default_action :create
unified_mode true

property :role_name,          String, name_property: true
property :url,                String, default: 'http://localhost:8500'
property :auth_token,         String, required: true
property :description,        String, default: ''
property :policies,           Array,  default: []
property :service_identities, Array,  default: []
property :ssl,                Hash,   default: {}
property :to_acl,             Hash,   default: lazy { default_acl }

action :create do
  configure_diplomat
  unless up_to_date?
    role = Diplomat::Role.list.select { |p| p['Name'] == new_resource.role_name }
    if role.empty?
      converge_by %(creating ACL role "#{new_resource.role_name}") do
        Diplomat::Role.create(new_resource.to_acl)
      end
    else
      converge_by %(updating ACL role "#{new_resource.role_name}") do
        Diplomat::Role.update(new_resource.to_acl.merge('ID' => role.first['ID']))
      end
    end
  end
end

action :delete do
  configure_diplomat
  converge_by %(deleting ACL role "#{new_resource.role_name}") do
    role = Diplomat::Role.list.select { |p| p['Name'] == new_resource.role_name }
    Diplomat::Role.delete(role['ID']) unless role.empty?
  end
end

action_class do
  include ConsulCookbook::Helpers

  def configure_diplomat
    begin
      require 'diplomat'
    rescue LoadError => e
      raise "The diplomat gem is required; include recipe[consul::client_gem] to install, details: #{e}"
    end
    Diplomat.configure do |config|
      config.url = new_resource.url
      config.acl_token = new_resource.auth_token
      config.options = { ssl: new_resource.ssl, request: { timeout: 10 } }
    end
  end

  def up_to_date?
    retry_block(max_tries: 3, sleep: 0.5) do
      old_role = Diplomat::Role.list.select { |p| p['Name'] == new_resource.role_name }.first
      return false if old_role.nil?
      old_role.select! { |k, _v| %w(Name Description Policies ServiceIdentities).include?(k) }
      old_role == new_resource.to_acl
    end
  end

  def retry_block(opts = {}, &_block)
    opts = {
      max_tries: 3, # Number of tries
      sleep: 0, # Seconds to sleep between tries
    }.merge(opts)

    try_count = 1
    begin
      yield try_count
    rescue Diplomat::UnknownStatus
      try_count += 1

      # If we've maxed out our attempts, raise the exception to the calling code
      raise if try_count > opts[:max_tries]

      # Sleep before the next retry if the option was given
      sleep opts[:sleep]

      retry
    end
  end

  def default_acl
    { 'Name' => new_resource.role_name,
      'Description' => new_resource.description,
      'Policies' => new_resource.policies,
      'ServiceIdentities' => new_resource.service_identities }
  end
end
