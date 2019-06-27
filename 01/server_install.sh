#!/bin/bash

#yum --quiet -y update

#yum --enablerepo=base clean metadata


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


sed -e '/^distroverpkg=.*/a proxy=libproxy' -i /etc/yum.conf

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



yum --quiet install -y mariadb-server

systemctl start mariadb
systemctl enable mariadb

#mysql -u root -e "create database zabbix character set utf8 collate utf8_bin; grant all privileges on zabbix.* to zabbix@192.168.55.56 identified by 'zabbix' with grant option;" 

mysql -u root -e "create database zabbix character set utf8 collate utf8_bin; grant all privileges on zabbix.* to zabbix@192.168.55.56 identified by 'zabbix' with grant option;
grant all privileges on zabbix.* to zabbix@localhost identified by 'zabbix' with grant option;"

sudo rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

rpm -ivh https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

#yum install --quiet -y https://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-release-4.0-1.el7.noarch.rpm

yum install --quiet -y zabbix-server-mysql zabbix-web-mysql

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix 

cd /etc/zabbix

sed -e '/DBHost=localhost/c\DBHost=192.168.55.56' -i zabbix_server.conf

sed -e '/DBPassword/c\DBPassword=zabbix' -i zabbix_server.conf

chown apache:apache -R /var/lib/php/session/

systemctl start zabbix-server

cd /etc/httpd/conf.d

sed -e '/php_value date.timezone/c\php_value date.timezone Europe/Minsk' -i zabbix.conf

systemctl start httpd





