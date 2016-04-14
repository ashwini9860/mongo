#
# Cookbook Name:: mongo
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.
#

#crete hostfile entry using hostsfile cookbook
#create alias for localhost
hostsfile_entry '127.0.0.1' do
  hostname  "mongo4"
  comment   'Append by chef Recipe '
  action    :append
end
#create new entry for primary  
hostsfile_entry "192.168.61.18" do
  hostname  "mongo1"
  action    :create_if_missing
end
#create new entry for secondary
hostsfile_entry "192.168.61.19" do
  hostname  "mongo2"
  action    :create_if_missing
end
#create new entry for secondary
hostsfile_entry "192.168.61.20" do
  hostname  "mongo3"
  action    :create_if_missing
end

#create data dir for mongodb
directory "/data/mongo/" do
  recursive true
  owner 'mongod'
  group 'mongod'
  mode '0755'
  action :create
end

#create pid for mongodb
file "/data/mongo.pid" do
  mode '0755'
  owner 'mongod'
  group 'mongod'
  action :create
end

#create syslog for mongodb
file "/data/mongo.log" do
  mode '0755'
  owner 'mongod'
  group 'mongod'
  action :create
end

#ser permission recursively
execute "set owners mongod" do
  command "chown mongod:mongod /data/mongo/ -R"
  action :run
end

#create repo for mongodb using yum cookbook
yum_repository "mongod-org-3.2" do
  description "mongod 0rg 3.2"
  baseurl "https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64/"
  gpgkey "https://www.mongodb.org/static/pgp/server-3.2.asc"
  action :create
end

#install mongodb
package "mongodb-org" do
 action :install
end

#copy mongod.conf to mongod.conf.disable
execute "copy" do
command "cp /etc/mongod.conf /etc/mongod.conf.disable"
   action :run
   not_if do
   File.exist?("/etc/mongod.conf.disable")
end
end

#mongod.conf file
template "/etc/mongod.conf" do
source "mongod.conf.erb"
variables(
	:syspath => node['mongo']['syspath'],
	:dbpath => node['mongo']['dbpath'],
	:fork => node['mongo']['fork'],
	:port => node['mongo']['port'],
	:pidpath => node['mongo']['pidpath'],
	:replname => node['mongo']['replname']
)
mode "0755"
action :create
end

#start mongod with config file
#execute "config-start" do
#  command "mongod --config /etc/mongod.conf"
#  action :run
#end

#servic estart mongodb
 service "mongod" do
 action [ :enable, :start]
end


#bash script to run mongodb command
bash 'checking primary master & add node' do
  user 'root'
  cwd '/tmp'
  code <<-EOH
   a=$(mongo mongo1:27017 --quiet --eval 'db.isMaster().ismaster')
   b=$(mongo mongo2:27017 --quiet --eval 'db.isMaster().ismaster')
   c=$(mongo mongo3:27017 --quiet --eval 'db.isMaster().ismaster')
   d=$(mongo mongo4:27017 --quiet --eval 'db.isMaster().ismaster')
   e=$(mongo --quiet --eval 'rs.status()' | grep "name" | cut -d"\"" -f4 | cut -d ":" -f1 | grep "mongo1")
   f=$(mongo --quiet --eval 'rs.status()' | grep "name" | cut -d"\"" -f4 | cut -d ":" -f1 | grep "mongo2")
   g=$(mongo --quiet --eval 'rs.status()' | grep "name" | cut -d"\"" -f4 | cut -d ":" -f1 | grep "mongo3")
   h=$(mongo --quiet --eval 'rs.status()' | grep "name" | cut -d"\"" -f4 | cut -d ":" -f1 | grep "mongo4")
   if [ $a == true ]
   then
   if [ $e != mongo1 ]
   then
     mongo --eval 'rs.add("mongo1")'
   elif [ $f != mongo2 ]
   then
     mongo --eval 'rs.add("mongo2")'
   elif [ $g != mongo3 ]
   then
     mongo --eval 'rs.add("mongo3")'
   elif [ $h != mongo4 ]
   then
     mongo --eval 'rs.add("mongo4")'
   fi
   fi
   if [ $b == true ]
   then
   if [ $e != mongo1 ]
   then
     mongo --eval 'rs.add("mongo1")'
   elif [ $f != mongo2 ]
   then
     mongo --eval 'rs.add("mongo2")'
   elif [ $g != mongo3 ]
   then
     mongo --eval 'rs.add("mongo3")'
   elif [ $h != mongo4 ]
   then
     mongo --eval 'rs.add("mongo4")'
   fi
   fi
   if [ $c == true ]
   then
   if [ $e != mongo1 ]
   then
     mongo --eval 'rs.add("mongo1")'
   elif [ $f != mongo2 ]
   then
     mongo --eval 'rs.add("mongo2")'
   elif [ $g != mongo3 ]
   then
     mongo --eval 'rs.add("mongo3")'
   elif [ $h != mongo4 ]
   then
     mongo --eval 'rs.add("mongo4")'
   fi
   fi
   if [ $d == true ]
   then
   if [ $e != mongo1 ]
   then
     mongo --eval 'rs.add("mongo1")'
   elif [ $f != mongo2 ]
   then
     mongo --eval 'rs.add("mongo2")'
   elif [ $g != mongo3 ]
   then
     mongo --eval 'rs.add("mongo3")'
   elif [ $h != mongo4 ]
   then
     mongo --eval 'rs.add("mongo4")'
   fi
   fi

   EOH
end
