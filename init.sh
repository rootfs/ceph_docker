#!/bin/sh
#set -e
set -x

rm -f /etc/ceph/*

MASTER=`hostname -s`

#create ceph cluster
ceph-deploy --overwrite-conf new ${MASTER}  
ceph-deploy --overwrite-conf mon create-initial ${MASTER}
ceph-deploy --overwrite-conf mon create ${MASTER}
ceph-deploy  gatherkeys ${MASTER}  

for i in 0 1 2
do
	ceph osd create
	ceph-osd -i ${i} --mkfs --mkkey
	ceph auth add osd.${i} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-${i}/keyring
	ceph osd crush add ${i} 1 root=default host=${MASTER}
	ceph-osd -i ${i} -k /var/lib/ceph/osd/ceph-${i}/keyring
done


#start ceph 
#service ceph restart

ps -ef |grep ceph

#see if we are ready to go  
ceph osd tree  
#ceph health should be clean+ok  
ceph health  

# create ceph fs
ceph osd pool create cephfs_data 4
ceph osd pool create cephfs_metadata 4
ceph fs new cephfs cephfs_metadata cephfs_data
ceph-deploy mds create ${MASTER}

ps -ef |grep ceph


ceph -w
