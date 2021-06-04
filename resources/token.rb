#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_token
default_action :create
unified_mode true

property :description,        String, name_property: true
property :url,                String, default: 'http://localhost:8500'
property :auth_token,         String, required: true
property :secret_id,          String
property :policies,           Array,  default: []
property :roles,              Array,  default: []
property :service_identities, Array,  default: []
property :expiration_time,    String, default: ''
property :expiration_ttl,     String
property :local,              [true, false]
property :ssl,                Hash,   default: {}
property :to_acl,             Hash,   default: lazy { default_acl }

action :create do
  configure_diplomat
  unless up_to_date?
    old_token = Diplomat::Token.list.select { |p| p['Description'].downcase == new_resource.description.downcase }
    if old_token.empty?
      converge_by %(creating ACL token "#{new_resource.description.downcase}") do
        Diplomat::Token.create(new_resource.to_acl)
      end
    else
      converge_by %(updating ACL token "#{new_resource.description.downcase}") do
        Diplomat::Token.update(new_resource.to_acl.merge('AccessorID' => old_token.first['AccessorID']))
      end
    end
  end
end

action :delete do
  configure_diplomat
  converge_by %(deleting ACL token "#{new_resource.description.downcase}") do
    token = Diplomat::Token.list.select { |p| p['Description'].downcase == new_resource.description.downcase }
    Diplomat::Token.delete(token['AccessorID']) unless token.empty?
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
      old_token_id = Diplomat::Token.list.select { |p| p['Description'].downcase == new_resource.description.downcase }
      if old_token_id.empty?
        Chef::Log.warn %(Token with description "#{new_resource.description.downcase}" was not found. Will create.)
        return false
      end
      old_token = Diplomat::Token.read(old_token_id.first['AccessorID'], {}, :return)
      old_token.select! { |k, _v| %w(SecretID Description Policies Local).include?(k) }
      old_token['Description'].downcase!
      old_token == new_resource.to_acl
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
    { 'SecretID' => new_resource.secret_id,
      'Description' => new_resource.description.downcase,
      'Local' => new_resource.local,
      'Policies' => [ new_resource.policies.each_with_object({}) { |k, h| h['Name'] = k } ],
    }
  end
end
