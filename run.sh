docker build -t centos_ceph_pkg .
mkdir -p /home/etc
mkdir -p /home/etc/ceph
mkdir -p /ceph/disks

umount /tmp/ceph_disk0
dd if=/dev/zero of=/ceph/disks/d0 bs=256M count=5 conv=notrunc
mkfs -t xfs -f /ceph/disks/d0
mkdir -p /tmp/ceph_disk0
mount -t xfs -o loop /ceph/disks/d0 /tmp/ceph_disk0

docker run --privileged --net=host -i -t  -v /tmp/ceph_disk0:/var/lib/ceph/osd/ceph-0 -v /etc/ceph:/etc/ceph  -t centos_ceph_pkg /bin/bash /init.sh
