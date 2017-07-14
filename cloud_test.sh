#!/bin/bash

set -x

test $VENV_NAME || export VENV_NAME=aio_tempest
test $CLOUD_USER || CLOUD_USER=ubuntu
test $KEY_FILE || KEY_FILE=cloud/cloudallinone.pem
test $VIRTUAL_ENV || export VIRTUAL_ENV=`pwd`/aiocloud
test -d $VIRTUAL_ENV || virtualenv $VIRTUAL_ENV && sleep 3

source cloud/oscore.rc
source $VIRTUAL_ENV/bin/activate

chmod g-rwx,o-rwx $KEY_FILE

pip install -r cloud/requirements.txt --upgrade

openstack --insecure server create \
  --image ubuntu-16-04-amd64-cloudimg \
  --flavor oc_aio_large \
  --nic net-id=private \
  --availability-zone mcp-oscore \
  --key cloudallinone $VENV_NAME || exit 1

sleep 10
IP=`openstack --insecure floating ip list | grep None | head -n1 | awk ' { print $4 } '`
openstack --insecure server add floating ip $VENV_NAME $IP || exit 1
ssh-keygen -f ~/.ssh/known_hosts -R $IP
sleep 20

ansible-playbook aio.yml -i "$IP, " \
  --user=$CLOUD_USER \
  --key-file=$KEY_FILE || exit 1

ansible-playbook run_tempest.yml -i "$IP, " \
  --user=$CLOUD_USER \
  --key-file=$KEY_FILE || exit 1

ansible-playbook get_results.yml -i "$IP, " \
  --user=$CLOUD_USER \
  --key-file=$KEY_FILE || exit 1

test $ERASE_VENV && openstack --insecure server delete $VENV_NAME
