#
# Cookbook: consul
# License: Apache 2.0
#
# Copyright:: 2014-2016, Bloomberg Finance L.P.
#

module ConsulCookbook
  module Helpers
    include Chef::Mixin::ShellOut

    extend self

    def arch_64?
      Chef.node['kernel']['machine'] =~ /x86_64/ ? true : false
    end

    def windows?
      Chef.node['os'].eql?('windows') ? true : false
    end

    # returns windows friendly version of the provided path,
    # ensures backslashes are used everywhere
    # Gently plucked from https://github.com/chef-cookbooks/windows
    def win_friendly_path(path)
      path.gsub(::File::SEPARATOR, ::File::ALT_SEPARATOR || '\\') if path
    end

    # Simply using ::File.join was causing several attributes
    # to return strange values in the resources (e.g. "C:/Program Files/\\consul\\data")
    def join_path(*path)
      windows? ? win_friendly_path(::File.join(path)) : ::File.join(path)
    end

    def program_files
      join_path('C:', 'Program Files') + (arch_64? ? '' : ' x(86)')
    end

    def config_prefix_path
      windows? ? join_path(program_files, 'consul') : join_path('/etc', 'consul')
    end

    def data_path
      windows? ? join_path(program_files, 'consul', 'data') : join_path('/var', 'lib', 'consul')
    end

    def extract_path
      windows? ? join_path(program_files, 'consul') : join_path('/opt', 'consul')
    end

    def install_path
      windows? ? join_path(program_files, 'consul', 'consul.exe') : join_path('/usr', 'local', 'bin', 'consul')
    end

    def shell_environment
      shell = Chef.node['consul']['service_shell']
      shell.nil? ? {} : { 'SHELL' => shell }
    end

    def default_environment
      {
        'GOMAXPROCS' => [Chef.node['cpu']['total'], 2].max.to_s,
        'PATH' => '/usr/local/bin:/usr/bin:/bin',
      }.merge(shell_environment)
    end
  end
end
