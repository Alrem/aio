#!/bin/bash

git clone https://github.com/andreyshestakov/mcp-aio /srv/salt/reclass
cd /srv/salt/reclass
git clone https://gerrit.mcp.mirantis.net/p/salt-models/reclass-system.git classes/system
ln -s /usr/share/salt-formulas/reclass/service classes/service

export FORMULAS_BASE=https://gerrit.mcp.mirantis.net/salt-formulas
export FORMULAS_PATH=/root/formulas
export FORMULAS_BRANCH=master

mkdir -p ${FORMULAS_PATH}
declare -a formula_services=("linux" "reclass" "salt" "openssh" "ntp" "git" "nginx" "collectd" "sensu" "heka" "sphinx" "mysql" "grafana" "libvirt" "rsyslog" "memcached" "rabbitmq" "apache" "keystone" "glance" "nova" "neutron" "cinder" "heat" "horizon")
for formula_service in "${formula_services[@]}"; do
  _BRANCH=${FORMULAS_BRANCH}
    [ ! -d "${FORMULAS_PATH}/${formula_service}" ] && {
      if ! git ls-remote --exit-code --heads ${FORMULAS_BASE}/${formula_service}.git ${_BRANCH};then
        # Fallback to the master branch if the branch doesn't exist for this repository
        _BRANCH=master
      fi
      git clone ${FORMULAS_BASE}/${formula_service}.git ${FORMULAS_PATH}/${formula_service} -b ${_BRANCH}
    } || {
      cd ${FORMULAS_PATH}/${formula_service};
      git fetch ${_BRANCH} || git fetch --all
      git checkout ${_BRANCH} && git pull || git pull;
      cd -
  }
  cd ${FORMULAS_PATH}/${formula_service}
  make install
  cd -
done
