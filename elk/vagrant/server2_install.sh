#!/bin/bash

#yum --quiet -y update

start_if_stopped () {
  if [ ! -z "$1" ]
  then
    service=$1
    value=$(service ${service} status | grep -c started)
    if [ $value -eq 0 ]
    then
      service ${service} start
    fi
  else
    printf "[ERROR] no parameter passed to start_if_stopped.\n"
  fi
}


yum --quiet install -y gcc gcc-c++ deltarpm epel-release  

yum --quiet install -y nginx

systemctl daemon-reload
systemctl enable nginx
systemctl stop nginx
systemctl stop iptables
systemctl disable iptables
systemctl start firewalld

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=9600/tcp --permanent


firewall-cmd --reload

yum --quiet install -y java-1.8.0-openjdk

update-alternatives --config java <<< 1


FILE=/usr/sbin/tomcat

if [ ! -f $FILE ]; then

    yum --quiet -y install tomcat

fi

cp /vagrant/clusterjsp.war /usr/share/tomcat/webapps/

start_if_stopped tomcat


cd /etc/nginx

cat > /etc/nginx/nginx.conf <<EOM
	
	worker_processes  1;

	events {
    		worker_connections  1024;
	}

	http {
	
		include     vhosts/backend.conf;
	}
EOM

mkdir vhosts

touch /etc/nginx/vhosts/backend.conf

cat > /etc/nginx/vhosts/backend.conf <<EOM
    server {

        listen 80;

        server_name 192.168.55.60;

       location / {
        proxy_pass http://192.168.55.60:8080/clusterjsp/;

        }
}
EOM

start_if_stopped nginx

cp /vagrant/logstash.repo /etc/yum.repos.d/

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

yum --quiet install -y logstash

systemctl enable logstash.service

rm -rf /etc/logstash/logstash.yml 

cp /vagrant/logstash.yml /etc/logstash/
cp /vagrant/tm.conf /etc/logstash/conf.d/

chmod -R 777 /usr/share/tomcat/logs/

systemctl start logstash.service


