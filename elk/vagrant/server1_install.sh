#!/bin/bash


sed -e '/^distroverpkg=.*/a proxy=libproxy' -i /etc/yum.conf

yum --quiet install -y gcc gcc-c++ deltarpm epel-release  

yum --quiet install -y nginx

cd /etc/nginx

cat > /etc/nginx/nginx.conf <<EOM
        
        worker_processes  1;

        events {
                worker_connections  1024;
        }

        http {
        
           server{
		
             listen 80;
	   }
        }
EOM


systemctl daemon-reload
systemctl enable nginx
systemctl stop nginx
systemctl stop iptables
systemctl disable iptables
systemctl start firewalld

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --zone=public --add-port=9200/tcp --permanent
firewall-cmd --zone=public --add-port=5601/tcp --permanent
firewall-cmd --zone=public --add-port=9300/tcp --permanent
firewall-cmd --reload

yum --quiet install -y java-1.8.0-openjdk

update-alternatives --config java <<< 1


cp /vagrant/elasticsearch.repo /etc/yum.repos.d/
yum --quiet install -y elasticsearch
systemctl enable elasticsearch.service


cp /vagrant/kibana.repo /etc/yum.repos.d/

yum --quiet install -y kibana
systemctl enable kibana.service

rm -rf /etc/kibana/kibana.yml
rm -rf /etc/elasticsearch/elasticsearch.yml

cp /vagrant/elasticsearch.yml /etc/elasticsearch/
cp /vagrant/kibana.yml /etc/kibana/

systemctl daemon-reload
systemctl start kibana.service
systemctl start elasticsearch.service

