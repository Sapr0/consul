#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_service, os: 'windows'
default_action :enable
unified_mode true

property :service_name, String, name_property: true
property :environment,  Hash,   default: lazy { default_environment }
property :acl_token,    String, default: lazy { node['consul']['config']['acl_master_token'] }
property :config_file,  String, default: lazy { node['consul']['config']['path'] }
property :data_dir,     String, default: lazy { node['consul']['config']['data_dir'] }
property :config_dir,   String, default: lazy { node['consul']['service']['config_dir'] }
property :nssm_params,  Hash,   default: lazy { node['consul']['service']['nssm_params'] }
property :program,      String, default: lazy { install_path }

action :enable do
  directories = %W(#{new_resource.data_dir}
                   #{new_resource.config_dir}
                   #{::File.dirname(new_resource.nssm_params['AppStdout'])}
                   #{::File.dirname(new_resource.nssm_params['AppStderr'])}).uniq.compact

  directories.delete_if { |i| i.eql? '.' }.each do |dirname|
    directory dirname do
      recursive true
    end
  end

  nssm 'consul' do
    program new_resource.program
    args %(agent -config-file="#{new_resource.config_file}" -config-dir="#{new_resource.config_dir}")
    parameters new_resource.nssm_params.select { |_k, v| v != '' }
    action :install
  end
end

action :reload do
  execute 'Reload consul' do
    cwd config_prefix_path
    command 'consul.exe reload' + (new_resource.acl_token ? " -token=#{new_resource.acl_token}" : '')
    action :run
  end
end

action :restart do
  powershell_script 'Restart consul' do
    code 'restart-service consul'
  end
end

action :disable do
  nssm 'consul' do
    action %i(stop remove)
  end

  file new_resource.config_file do
    action :delete
  end
end

action_class do
  include ConsulCookbook::Helpers
end
