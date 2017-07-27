#!/bin/bash
set -x

source /root/keystonercv3 || exit 1

glance image-create \
  --name cirros \
  --visibility public \
  --disk-format qcow2 \
  --container-format bare \
  --file /root/cirros-0.3.5-x86_64-disk.img \
  --progress || exit 1

#Allow ICMP
openstack security group rule create default \
  --protocol icmp \
  --remote-ip 0.0.0.0/0 || exit 1

#Allow TCP
openstack security group rule create default \
  --protocol tcp \
  --remote-ip 0.0.0.0/0 || exit 1

neutron net-create admin_internal || exit 1
neutron subnet-create --name internal_subnet admin_internal 192.168.1.0/24 || exit 1

neutron net-create admin_floating \
  --shared \
  --provider:network_type flat \
  --provider:physical_network physnet1  \
  --router:external || exit 1

neutron subnet-create \
  --name floating_subnet \
  --enable_dhcp=False \
  --allocation-pool=start=10.218.0.10,end=10.218.0.220 \
  --gateway=10.218.0.1 admin_floating 10.218.0.0/24 || exit 1

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

## Temporary disable
# sleep 15 #Time for building
# nova volume-attach test `cinder list | grep test | awk ' { print $2 } '`  || exit 1

#Check DNS
#openstack dns service list
#openstack zone create --email dnsmaster@example.tld example.tld.
#openstack recordset create --records '10.0.0.1' --type A example.tld. www
#nslookup www.example.tld 127.0.0.1


