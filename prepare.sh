#!/bin/bash

curl -q https://raw.githubusercontent.com/larsks/virt-utils/master/create-config-drive | sed s,/bin/sh,/bin/bash,g > create-config-drive.sh
chmod +x create-config-drive.sh

test -a ./xenial-server-cloudimg-amd64-disk1.img || wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img

sudo ./create-config-drive.sh -k ~/.ssh/id_rsa.pub -h mcp /var/lib/libvirt/aio_mcp.iso
sudo cp xenial-server-cloudimg-amd64-disk1.img /var/lib/libvirt/aio_mcp.img
sudo qemu-img resize /var/lib/libvirt/aio_mcp.img 120G

cat << 'EOF' > mcp_ext_net.xml
<network>
  <name>mcp_ext</name>
  <bridge name="mcp_ext"/>
  <forward mode="nat"/>
  <ip address="10.18.0.1" netmask="255.255.255.0" />
</network>
EOF

sudo virsh net-define mcp_ext_net.xml
sudo virsh net-autostart mcp_ext
sudo virsh net-start mcp_ext

sudo virt-install --name aio_mcp --ram 16384 --vcpus=4 --cpu host \
	--network network:mcp_ext,model=virtio \
	--disk path=/var/lib/libvirt/aio_mcp.img,bus=virtio,cache=none,format=qcow2 \
	--boot hd --vnc --console pty --autostart --noreboot \
	--disk path=/var/lib/libvirt/aio_mcp.iso,device=cdrom

sudo virsh net-update mcp_ext add \
       	ip-dhcp-host "<host mac='$(virsh domiflist aio_mcp | grep mcp_ext | awk '{print $5}')' name='aio_mcp' ip='10.18.0.2' /> "\
       	--live --config

sudo virsh start aio_mcp

ssh-keygen -f ~/.ssh/known_hosts -R 10.18.0.2


