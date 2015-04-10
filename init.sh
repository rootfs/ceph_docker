#!/bin/sh
#set -e
set -x

rm -f /etc/ceph/ceph*

#install_opt="--dev giant"
NODES=`hostname`
#on admin node, create ssh key and deploy on all NODES  
CLUSTER=""
for i in ${NODES[@]}
do
    echo $i
    CLUSTER=`echo -n $i $CLUSTER`
done

# choose the last node as master
MASTER=$i


#ceph-deploy install ${install_opt} ${CLUSTER}

#create ceph cluster
ceph-deploy --overwrite-conf new ${MASTER}  
ceph-deploy --overwrite-conf mon create-initial ${MASTER}
ceph-deploy --overwrite-conf mon create ${MASTER}
ceph-deploy  gatherkeys ${MASTER}  

for i in 0 1
do
	ceph osd create
	ceph-osd -i ${i} --mkfs --mkkey
	ceph auth add osd.${i} osd 'allow *' mon 'allow rwx' -i /var/lib/ceph/osd/ceph-${i}/keyring
	ceph osd crush add ${i} 1 root=default host=${MASTER}
	ceph-osd -i ${i} -k /var/lib/ceph/osd/ceph-${i}/keyring
done

set -e 
#ceph-deploy --overwrite-conf admin ${CLUSTER}

#start ceph on all NODES  
service ceph restart

ps -ef |grep ceph

#see if we are ready to go  
#osd tree should show all osd are up  
ceph osd tree  
#ceph health should be clean+ok  
ceph health  
# create a pool
#ceph osd pool create kube 16
#rados -p kube ls  

# create ceph fs
ceph-deploy mds create ${MASTER}
ceph osd pool create cephfs_data 4
ceph osd pool create cephfs_metadata 4
ceph fs new cephfs cephfs_metadata cephfs_data

service ceph restart

ceph osd pool create kube 4

ps -ef |grep ceph

#mount ceph fs  
#yum install -y ceph-fuse  
#mkdir -p /mnt/ceph 
#timeout 60s ceph-fuse -m ${MASTER}:6789 /mnt/ceph
#echo "mount status " $?
#should see cephfs mounted

ceph -w
