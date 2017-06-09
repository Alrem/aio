#!/bin/bash
set -x

source /root/keystonercv3

glance image-create \
  --name cirros \
  --visibility public \
  --disk-format qcow2 \
  --container-format bare \
  --file cirros-0.3.5-x86_64-disk.img \
  --progress

neutron net-create test

neutron subnet-create test 192.168.1.0/24

nova flavor-create m1.extra_tiny auto 256 0 1

nova boot --flavor m1.extra_tiny --image cirros --nic net-id=`neutron net-list | grep test | awk ' { print $2 } '` test

cinder create --name test 1

nova volume-attach test `cinder list | grep test | awk ' { print $2 } '`
