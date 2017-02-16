DIR=/db
IMAGE=centos_ceph
docker build -t ${IMAGE} .
mkdir -p ${DIR}/disks

umount /tmp/ceph_disk0
dd if=/dev/zero of=${DIR}/disks/d0 bs=256M count=5 conv=notrunc
mkfs -t xfs -f ${DIR}/disks/d0
mkdir -p /tmp/ceph_disk0
mount -t xfs -o loop ${DIR}/disks/d0 /tmp/ceph_disk0

rm -rf /etc/ceph/*
docker run --privileged --net=host -i -t  -v /tmp/ceph_disk0:/var/lib/ceph/osd/ceph-0 -v /etc/ceph:/etc/ceph -t ${IMAGE} /bin/bash /init.sh
