#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_acl
default_action :create
unified_mode true

property :id,         String, name_property: true
property :url,        String, default: 'http://localhost:8500'
property :auth_token, String, required: true
property :acl_name,   String, default: ''
property :type,       String, equal_to: %w(client management), default: 'client'
property :rules,      String, default: ''
property :ssl,        Hash,   default: {}
property :to_acl,     Hash,   default: lazy { default_acl }

action :create do
  configure_diplomat
  unless up_to_date?
    converge_by 'creating ACL' do
      Diplomat::Acl.create(new_resource.to_acl)
    end
  end
end

action :delete do
  configure_diplomat
  unless Diplomat::Acl.info(new_resource.id).empty?
    converge_by 'destroying ACL' do
      Diplomat::Acl.destroy(new_resource.id)
    end
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
      old_acl = Diplomat::Acl.info(new_resource.to_acl['ID'], {}, :return)
      return false if old_acl.nil? || old_acl.empty?
      old_acl.first.select! { |k, _v| %w(ID Type Name Rules).include?(k) }
      old_acl.first == new_resource.to_acl
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
    { 'ID' => new_resource.id, 'Type' => new_resource.type, 'Name' => new_resource.acl_name, 'Rules' => new_resource.rules }
  end
end
