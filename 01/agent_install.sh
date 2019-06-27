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
firewall-cmd --zone=public --add-port=10050/tcp --permanent
firewall-cmd --zone=public --add-port=10051/tcp --permanent

firewall-cmd --reload

yum --quiet install -y java-1.8.0-openjdk

update-alternatives --config java <<< 1


FILE=/usr/sbin/tomcat

if [ ! -f $FILE ]; then

    yum --quiet -y install tomcat

fi


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
        
        server{
	listen       80;
        server_name  192.168.55.55;
}

EOM

start_if_stopped nginx

yum install --quiet -y https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

yum install --quiet -y zabbix-agent

cd /etc/zabbix

sed '/ DebugLevel=3/s/^#//' -i zabbix_agentd.conf
sed -e '/ ListenPort=10050/s/^#//' -i zabbix_agentd.conf
sed -e '/ ListenIP=0.0.0.0/s/^#//' -i zabbix_agentd.conf
sed -e '/ StartAgents=3/s/^#//' -i zabbix_agentd.conf
sed -e '/Server=127.0.0.1/c\Server=192.168.55.56' -i zabbix_agentd.conf

systemctl restart zabbix-agent









