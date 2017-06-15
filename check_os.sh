#!/bin/bash
set -x

source /root/keystonercv3 || exit 1

ifconfig ens3 0.0.0.0 || exit 1
ovs-vsctl add-port br-floating ens3 || exit 1
ifconfig br-floating 10.18.0.2/24 || exit 1

glance image-create \
  --name cirros \
  --visibility public \
  --disk-format qcow2 \
  --container-format bare \
  --file /root/cirros-0.3.5-x86_64-disk.img \
  --progress || exit 1

openstack security group rule create default /
  --protocol icmp /
  --remote-ip 0.0.0.0/0 || exit 1

neutron net-create admin_internal || exit 1
neutron subnet-create --name internal_subnet admin_internal 192.168.1.0/24 || exit 1

neutron net-create admin_floating \
  --provider:network_type flat \
  --provider:physical_network physnet1  \
  --router:external || exit 1
neutron subnet-create \
  --name floating_subnet \
  --enable_dhcp=False \
  --allocation-pool=start=10.18.0.100,end=10.18.0.200 \
  --gateway=10.18.0.1 admin_floating 10.18.0.0/24 || exit 1

neutron router-create Router04 || exit 1
neutron router-gateway-set Router04 admin_floating || exit 1
neutron router-interface-add Router04 internal_subnet || exit 1

nova flavor-create m1.extra_tiny auto 256 0 1 || exit 1

nova boot \
  --flavor m1.extra_tiny \
  --image cirros \
  --nic net-id=`neutron net-list | grep admin_internal | awk ' { print $2 } '` \
  test || exit 1

cinder create --name test 1 || exit 1
sleep 15 #Time for building
nova volume-attach test `cinder list | grep test | awk ' { print $2 } '`  || exit 1


