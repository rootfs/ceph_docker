#!/bin/sh
#set -e
set -x

rm -f /etc/ceph/*

MASTER=`hostname -s`

ip=$(ip -4 -o a | grep eth0 | awk '{print $4}' | cut -d'/' -f1)
echo "$ip $MASTER" >> /etc/hosts

#create ceph cluster
ceph-deploy --overwrite-conf new ${MASTER}  
ceph-deploy --overwrite-conf mon create-initial ${MASTER}
ceph-deploy --overwrite-conf mon create ${MASTER}
ceph-deploy  gatherkeys ${MASTER}  

echo "osd crush chooseleaf type = 0" >> /etc/ceph/ceph.conf
echo "osd journal size = 100" >> /etc/ceph/ceph.conf
echo "osd pool default size = 1" >> /etc/ceph/ceph.conf
echo "osd pool default pgp num = 8" >> /etc/ceph/ceph.conf
echo "osd pool default pg num = 8" >> /etc/ceph/ceph.conf

/sbin/service ceph -c /etc/ceph/ceph.conf stop mon.${MASTER}
/sbin/service ceph -c /etc/ceph/ceph.conf start mon.${MASTER}

ceph osd pool set rbd size 1

ceph osd create
ceph-osd -i 0 --mkfs --mkkey
ceph auth add osd.0 osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-0/keyring
ceph osd crush add 0 1 root=default host=${MASTER}
ceph-osd -i 0 -k /var/lib/ceph/osd/ceph-0/keyring

#see if we are ready to go  
ceph osd tree  

# create ceph fs
ceph osd pool create cephfs_data 4
ceph osd pool create cephfs_metadata 4
ceph fs new cephfs cephfs_metadata cephfs_data
ceph-deploy --overwrite-conf mds create ${MASTER}

ps -ef |grep ceph
ceph osd dump
sleep 120

ceph -w
