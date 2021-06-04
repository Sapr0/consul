#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#
provides :consul_service
default_action :enable
unified_mode true

property :service_name, String, name_property: true
property :command,      String, required: true
property :config_file,  String, default: lazy { node['consul']['config']['path'] }
property :user,         String, default: lazy { node['consul']['service_user'] }
property :group,        String, default: lazy { node['consul']['service_group'] }
property :environment,  Hash,   default: lazy { default_environment }
property :data_dir,     String, default: lazy { node['consul']['config']['data_dir'] }
property :config_dir,   String, default: lazy { node['consul']['service']['config_dir'] }
property :nssm_params,  Hash,   default: lazy { node['consul']['service']['nssm_params'] }
property :program,      String, default: '/usr/local/bin/consul'
property :acl_token,    String, default: lazy { node['consul']['config']['acl_master_token'] }

action :enable do
  directory new_resource.data_dir do
    recursive true
    owner new_resource.user
    group new_resource.group
    mode '0750'
  end

  serv = service new_resource.service_name do
    action :nothing
  end

  if node['init_package'] == 'systemd'
    # TODO implement
  elsif node['init_package'] == 'upstart'
    # TODO implement
  else
    # Assumes sysvinit fallback
    script_path = "/etc/init.d/#{new_resource.service_name}"

    serv.init_command(script_path)
    serv.start_command("#{script_path} start")
    serv.stop_command("#{script_path} stop")
    serv.status_command("#{script_path} status")
    serv.restart_command("#{script_path} restart")
    serv.reload_command("#{script_path} reload")

    script_source = 'sysvinit.service.erb'
    script_source = 'sysvinit.service.debian.erb' if debian?
    template script_path do
      source script_source
      owner 'root'
      group 'root'
      mode '0755'
      variables(
        name: new_resource.service_name,
        user: new_resource.user,
        program: new_resource.program,
        data_dir: new_resource.data_dir,
        config_file: new_resource.config_file,
        config_dir: new_resource.config_dir,
        environment: new_resource.environment
      )
      notifies :restart, "service[#{new_resource.service_name}]"
    end
  end

  # services resource
  serv
end

action :disable do
  service new_resource.service_name do
    action :disable
  end
end

action :start do
  service new_resource.service_name do
    action :start
  end
end

action :stop do
  service new_resource.service_name do
    action :stop
  end
end

action :restart do
  service new_resource.service_name do
    action :restart
  end
end

action :reload do
  service new_resource.service_name do
    action :reload
  end
end

action_class do
  include ConsulCookbook::Helpers

  def shell_environment
    shell = node['consul']['service_shell']
    shell.nil? ? {} : { 'SHELL' => shell }
  end

  def default_environment
    {
      'GOMAXPROCS' => [node['cpu']['total'], 2].max.to_s,
      'PATH' => '/usr/local/bin:/usr/bin:/bin',
    }.merge(shell_environment)
  end
end
