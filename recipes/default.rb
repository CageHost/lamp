#
# Cookbook Name:: cmd_lamp
# Recipe:: default
#
# Copyright (C) 2014 YOUR_NAME
#
# All rights reserved - Do Not Redistribute
#

recipes = [
	"apt",
	"build-essential",
	"git",
	"php",
	"apache2",
	"apache2::mod_php5",
	"apache2::mod_rewrite",
	"mysql::server",
	"composer",
	"nodejs::install_from_source",
]

for r in recipes do
  include_recipe r
end

# Install packages and software

packages = [
	"nano",
	"php5-curl",
	"php5-mcrypt",
	"php5-mysql",
	"php5-gd",
	"php5-imagick",
	"php-apc",
  "sendmail-bin",
	"sendmail",
]

for p in packages do
  package p do
    action [:install]
  end
end

execute "gem install" do
  command "gem install compass"
  notifies :create, "ruby_block[gem_set_installed]", :immediately
  not_if { node.attribute?("gem_installed") }
end

execute "npm install" do
  command "npm install -g grunt-cli forever"
  notifies :create, "ruby_block[npm_set_installed]", :immediately
  not_if { node.attribute?("npm_installed") }
end

ruby_block "gem_set_installed" do
  block do
    node.set['npm_installed'] = true
    node.save
  end
  action :nothing
end

ruby_block "npm_set_installed" do
  block do
    node.set['npm_installed'] = true
    node.save
  end
  action :nothing
end

# Add templates, fix permissions and add key

template "/usr/local/bin/devadd" do
  source "devadd.erb"
  owner "root"
  group "staff"
  mode "0755"
end

template "/usr/local/bin/chweb" do
  source "chweb.erb"
  owner "root"
  group "staff"
  mode "0755"
end

directory "/etc/php5/apache2" do
  owner "root"
  group "root"
  mode "0755"
  action :create
end

template "/etc/php5/apache2/php.ini" do
  source "php.ini-dev.erb"
  owner "root"
  group "root"
  mode "0644"
end

execute 'chweb' do
  command "chweb dev /var/www"
end

if !node['cmd_lamp']['public_key'].nil? && !node['cmd_lamp']['public_key'].empty?
  execute 'devadd' do
    command "devadd #{node['cmd_lamp']['username']} \"#{node['cmd_lamp']['public_key']}\""
  end
end

# Create virtual hosts

sites = data_bag("sites")

sites.each do |s|
	site = data_bag_item("sites", s)
	web_app site["id"] do
		template "site.conf.erb"
	  server_name site["id"]
	  docroot "/var/www/" + site["dir"]
	end
end