#!/bin/bash
set -e

# Upgrade Kubernetes 

export KUBELET_TARGET_VERSION=v1.2.0_coreos.0

# get current kubelet version
export KUBELET_VERSION=$(cat /etc/systemd/system/kubelet.service | grep KUBELET_VERSION | awk 'BEGIN{FS="="} {print $3}')

# Stop script if nothing to do 
if [ "$USER" == "root" ]; then 
	echo "This script needs root rights"
	exit
fi

# Stop script if nothing to do 
if [ "$KUBELET_VERSION" == "$KUBELET_TARGET_VERSION" ]; then 
	echo "Kubelet already up to date, nothing to do"
	exit
fi

if [ -f /etc/kubernetes/manifests/kube-apiserver.yaml ] ; then export KUBERNETES_ROLE=master; fi

# stop kubelet
systemctl stop kubelet

# Replace Kubelet Daemon and Kubernetes Manifiests
sed -i 's/KUBELET_VERSION='$KUBELET_VERSION'/KUBELET_VERSION='$KUBELET_TARGET_VERSION'/g' /etc/systemd/system/kubelet.service  
find /etc/kubernetes/manifests -type f -exec sed -i 's/'$KUBELET_VERSION'/'$KUBELET_TARGET_VERSION'/g' {} \;
find /srv/kubernetes/manifests -type f -exec sed -i 's/'$KUBELET_VERSION'/'$KUBELET_TARGET_VERSION'/g' {} \;

# stop kubernetes containers
K8dockerContainers=( pause hyperkube podmaster )
for i in "${K8dockerContainers[@]}"
do
   echo Stopping Container: $i
   docker ps | grep $i | awk '{system ("docker stop " $1)}'
   echo Killing Container:$i 
   docker ps | grep $i | awk '{system ("docker kill " $1)}'
   # do whatever on $i
done

docker rm -v $(docker ps -a -q -f status=exited)

systemctl start kubelet
systemctl daemon-reload