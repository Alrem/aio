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

neutron net-create admin_internal

neutron subnet-create --name internal_subnet admin_internal 192.168.1.0/24


neutron net-create admin_floating --provider:network_type flat --provider:physical_network physnet1  --router:external
neutron subnet-create --name floating_subnet --enable_dhcp=False --allocation-pool=start=10.18.0.100,end=10.18.0.200 --gateway=10.18.0.1 admin_floating 10.18.0.0/24
neutron router-create Router04
neutron router-gateway-set Router04 admin_floating
neutron router-interface-add router1 admin_internal


nova flavor-create m1.extra_tiny auto 256 0 1

nova boot --flavor m1.extra_tiny --image cirros --nic net-id=`neutron net-list | grep admin_internal | awk ' { print $2 } '` test

cinder create --name test 1

nova volume-attach test `cinder list | grep test | awk ' { print $2 } '`


