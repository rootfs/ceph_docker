#!/bin/sh
yum update -y -v
rpm -Uvh http://ceph.com/rpm/rhel6/noarch/ceph-release-1-0.el6.noarch.rpm
yum install   python-itsdangerous python-werkzeug python-jinja2 python-flask  -y 
yum install   openssh openssh-server openssh-clients hostname -y -q
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
cat ~/.ssh/id_rsa.pub |awk '{print $1, $2, "Generated"}' >> ~/.ssh/authorized_keys2
cat ~/.ssh/id_rsa.pub |awk '{print $1, $2, "Generated"}' >> ~/.ssh/authorized_keys

yum install  -y -q ceph-deploy epel-release 
yum install -y ceph
