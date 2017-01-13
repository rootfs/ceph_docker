#!/bin/sh
#set -e
set -x

function restart_mon {
   pkill -9  ceph-mon
   sleep 3
   ceph-mon -f --cluster ceph --id ${MASTER}  &
   sleep 3
}

pkill -9 ceph-mon
pkill -9 ceph-osd

mkdir -p /etc/ceph
mkdir -p /etc/ceph
rm -rf /etc/ceph/*
rm -rf /var/lib/ceph/osd/ceph-0/
rm -rf /var/run/ceph

MASTER=`hostname -s`

ip=$(ip -4 -o a | grep eth0 | awk '{print $4}' | cut -d'/' -f1)
echo "$ip $MASTER" >> /etc/hosts

# purge
ceph-deploy purgedata ${MASTER}
ceph-deploy forgetkeys

#create ceph cluster
ceph-deploy --overwrite-conf new ${MASTER}  
ceph-deploy  mon create-initial 
ceph-deploy --overwrite-conf mon create ${MASTER} #systemctl could fail!
restart_mon
ceph-deploy  gatherkeys ${MASTER}  

ceph --connect-timeout=25 --cluster=ceph --name mon. --keyring=/var/lib/ceph/mon/ceph-rootfs-dev/keyring auth get client.admin >  /etc/ceph/ceph.client.admin.keyring
echo "osd crush chooseleaf type = 0" >> /etc/ceph/ceph.conf
echo "osd journal size = 100" >> /etc/ceph/ceph.conf
echo "osd pool default size = 1" >> /etc/ceph/ceph.conf
echo "osd pool default pgp num = 8" >> /etc/ceph/ceph.conf
echo "osd pool default pg num = 8" >> /etc/ceph/ceph.conf

restart_mon

ceph osd pool set rbd size 1

ceph osd create
ceph-osd -i 0 --mkfs --mkkey
ceph auth add osd.0 osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-0/keyring
ceph osd crush add 0 1 root=default host=${MASTER}
ceph-osd -i 0 -k /var/lib/ceph/osd/ceph-0/keyring

#see if we are ready to go  
ceph osd tree  

#create pool for kubernets test
ceph osd pool create kube 4
rbd create foo --size 10 --pool kube

# create a known keyring
cat > /etc/ceph/ceph.client.kube.keyring <<EOF
[client.kube]
        key = AQAMgXhVwBCeDhAA9nlPaFyfUSatGD4drFWDvQ==
        caps mds = "allow rwx"
        caps mon = "allow rwx"
        caps osd = "allow rwx"
EOF
ceph auth import -i /etc/ceph/ceph.client.kube.keyring

ps -ef |grep ceph
ceph osd dump
sleep 120

ceph -w
