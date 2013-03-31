#
# Cookbook Name:: asterisk
# Recipe:: default
#
# Copyright 2011, Chris Peplin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform']
when "ubuntu","debian"
  if node['asterisk']['use_digium_repo']
    apt_repository "asterisk" do
      uri "http://packages.asterisk.org/deb"
      components ["lucid", "main"]
      action :add
    end

    execute "update-asterisk-repo" do
      command "apt-get update"
    end
  end

  node['asterisk']['packages'].each do |pkg|
    package pkg do
      options "--force-yes"
    end
  end
end

service "asterisk" do
  supports :restart => true, :reload => true, :status => :true, :debug => :true,
    "logger-reload" => true, "extensions-reload" => true,
    "restart-convenient" => true, "force-reload" => true
end

external_ip = node[:ec2] ? node[:ec2][:public_ipv4] : node[:ipaddress]
#chef-solo does not like recipes that search
#users = search(:asterisk_users) || []
#auth = search(:auth, "id:google") || []
#dialplan_contexts = search(:asterisk_contexts) || []
users = []
auth = []
dialplan_contexts = []

%w{sip manager modules extensions gtalk jabber}.each do |template_file|
  template "/etc/asterisk/#{template_file}.conf" do
    source "#{template_file}.conf.erb"
    owner "asterisk"
    group "asterisk"
    mode 0644
    variables :external_ip => external_ip, :users => users, :auth => auth[0], :dialplan_contexts => dialplan_contexts
    notifies :reload, resources(:service => "asterisk")
  end
end
