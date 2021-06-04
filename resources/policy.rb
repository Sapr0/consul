#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_policy
default_action :create
unified_mode true

property :policy_name, String, name_property: true
property :url,         String, default: 'http://localhost:8500'
property :auth_token,  String, required: true
property :description, String, default: ''
property :datacenters, Array,  default: []
property :rules,      String,  default: ''
property :ssl,        Hash,    default: {}
property :to_acl,     Hash,    default: lazy { default_acl }

action :create do
  configure_diplomat
  unless up_to_date?
    policy = Diplomat::Policy.list.select { |p| p['Name'].downcase == new_resource.policy_name.downcase }
    if policy.empty?
      converge_by %(creating ACL policy "#{new_resource.policy_name.downcase}") do
        Diplomat::Policy.create(new_resource.to_acl)
      end
    else
      converge_by %(updating ACL policy "#{new_resource.policy_name.downcase}") do
        Diplomat::Policy.update(new_resource.to_acl.merge('ID' => policy.first['ID']))
      end
    end
  end
end

action :delete do
  configure_diplomat
  converge_by %(deleting ACL policy "#{new_resource.policy_name.downcase}") do
    policy = Diplomat::Policy.list.select { |p| p['Name'].downcase == new_resource.policy_name.downcase }
    Diplomat::Policy.delete(policy['ID']) unless policy.empty?
  end
end

action_class do
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
      old_policy_id = Diplomat::Policy.list.select { |p| p['Name'].downcase == new_resource.policy_name.downcase }
      return false if old_policy_id.empty?
      old_policy = Diplomat::Policy.read(old_policy_id.first['ID'], {}, :return)
      return false if old_policy.nil?
      old_policy.first.select! { |k, _v| %w(Name Description Rules).include?(k) }
      old_policy['Description'].downcase!
      old_policy.first == new_resource.to_acl
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
    { 'Name' => new_resource.policy_name,
      'Description' => new_resource.description,
      'Datacenters' => new_resource.datacenters,
      'Rules' => new_resource.rules }
  end
end
