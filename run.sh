docker build -t centos_ceph_pkg .
mkdir -p /home/etc
mkdir -p /home/etc/ceph
mkdir -p /home/disks

for i in 0 1
do
  umount /tmp/ceph_disk${i}
  dd if=/dev/zero of=/home/disks/d${i} bs=1024M count=6 conv=notrunc
  mkfs -t xfs -f /home/disks/d${i}
  mkdir -p /tmp/ceph_disk${i}
  mount -t xfs -o loop  /home/disks/d${i} /tmp/ceph_disk${i}
done

docker run --privileged --net=host -i -t  -v /tmp/ceph_disk0:/var/lib/ceph/osd/ceph-0 -v /tmp/ceph_disk1:/var/lib/ceph/osd/ceph-1  -v /etc/ceph:/etc/ceph  -t centos_ceph_pkg /bin/bash /init.sh


