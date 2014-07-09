#
# Cookbook Name:: lamp
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
  not_if "gem list compass -i"
end

execute "npm install" do
  command "npm install -g grunt-cli forever"
  not_if "npm list -g | grep 'grunt-cli\|forever'"
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

# Add the user if they do not exist

execute 'devadd' do
  command "devadd #{node['lamp']['username']} \"#{node['lamp']['public_key']}\""
  not_if "id -u #{node['lamp']['username']}"
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