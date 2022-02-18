#!/bin/bash 

      set -ex
      openssl x509 -enddate -noout -in /etc/ssl/certs/DST_Root_CA_X3.pem
      sudo sed -i"" 's/mozilla\/DST_Root_CA_X3.crt/!mozilla\/DST_Root_CA_X3.crt/' /etc/ca-certificates.conf
      sudo dpkg-reconfigure -fnoninteractive ca-certificates
      sudo update-ca-certificates
      openssl x509 -enddate -noout -in /etc/ssl/certs/ISRG_Root_X1.pem

      echo DefaultTasksMax=1000000 | sudo tee /etc/systemd/system.conf
      sudo systemctl daemon-reload
      sudo systemctl daemon-reexec
      sudo service systemd-logind restart
      git config --global http.sslVerify false # Do NOT do this!
      sudo apt update
      sudo apt install git curl make -y
      sudo rm -f /usr/lib/python3/dist-packages/PyYAML-3.12.egg-info
      sudo apt install python3-pip python3-setuptools -y
      sudo pip3 install PyYAML
      sudo apt install python-pip python-setuptools -y
      sudo apt install python-cmd2 python-openstackclient python-heatclient -y
      git clone https://opendev.org/airship/treasuremap/
      cd ./treasuremap/
      git checkout v1.8-prime
      ./tools/deployment/airskiff/developer/000-clone-dependencies.sh
      ./tools/deployment/airskiff/developer/009-setup-apparmor.sh
      sleep 5
      cd ../openstack-helm-infra/
      cp ../openstack-helm-infra.diff ./
      git apply openstack-helm-infra.diff
      cd ../treasuremap/
      ./tools/deployment/airskiff/developer/020-setup-client.sh
      ./tools/deployment/airskiff/developer/010-deploy-k8s.sh

      chmod 777 ~/.kube/config

      sudo cp /etc/resolv.conf /etc/resolv.conf.backup
      sudo bash -c 'echo '\''nameserver 10.96.0.10'\'' > /etc/resolv.conf'
      sudo bash -c 'echo '\''nameserver 8.8.8.8'\'' >> /etc/resolv.conf'
      sudo bash -c 'echo '\''nameserver 8.8.4.4'\'' >> /etc/resolv.conf'
      sudo bash -c 'echo '\''search svc.cluster.local cluster.local'\'' >> /etc/resolv.conf'
      sudo bash -c 'echo '\''options ndots:5 timeout:1 attempts:1'\'' >> /etc/resolv.conf'
      sudo rm /etc/resolv.conf.backup
      cd ../armada
      git checkout a1b693b84d97f2cd0e0f9482d2f85a894c45c265
      cp ../armada.diff ./
      git apply armada.diff
      make charts
      sudo apt install tox -y
      sleep 5
      tox -e genconfig
      tox -e genpolicy
      make images
      sleep 5
      cd ../treasuremap/
      git checkout 1678cf635fe7ae7130c0dbef8dfb5494b8c69c16
      cp ../treasuremap.diff ./
      git apply treasuremap.diff    
      ./tools/deployment/airskiff/developer/030-armada-bootstrap.sh
      export OS_CLOUD=airship
      openstack endpoint list
      openstack service list
      cd ../shipyard
      git checkout 30f3a989c7
      cd ../treasuremap
      ./tools/deployment/airskiff/developer/100-deploy-osh.sh
      #kubectl apply -f https://k8s.io/examples/admin/dns/dnsutils.yaml
# 2022-02-09 20:46:02.688 1 INFO armada.handlers.chart_download [-] Cloning repo: https://opendev.org/openstack/openstack-helm-infra from branch: 03580ec90afa162c166661acf27f351b83565375
# 2022-02-09 20:46:05.430 1 INFO armada.handlers.chart_download [-] Cloning repo: https://opendev.org/openstack/openstack-helm from branch: 52c132b9356695bf455ae25ec78cef9f532f9fe8