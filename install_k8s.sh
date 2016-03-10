#!/bin/bash

# Install Kubernetes on CoreOS alpha

# ETCD_API=`curl https://discovery.etcd.io/new`

# Generate keys - Master 
cp openssl.cnf
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"
openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

# Generate Keys - Nodes
WORKER_IP=
WORKER_FQDN=
cp worker-openssl.cnf
openssl genrsa -out $WORKER_FQDN-worker-key.pem 2048
openssl req -new -key $WORKER_FQDN-worker-key.pem -out ${WORKER_FQDN}-worker.csr -subj "/CN=$WORKER_FQDN" -config worker-openssl.cnf
openssl x509 -req -in $WORKER_FQDN-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out $WORKER_FQDN-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf


# Copy kube-controller-manager.yaml,kube-scheduler.yaml  into /srv/kubernetes/manifests
sudo mkdir /srv/kubernetes
sudo mkdir /srv/kubernetes/manifests
cp kube-controller-manager.yaml /srv/kubernetes/manifests
cp kuber-scheduler.yaml /srv/kubernetes/manifests

# Load changed units
sudo systemctl daemon-reload

# Configure Flannel
# Replace $POD_NETWORK
# Replace $ETCD_SERVER with one url (http://ip:port) from $ETCD_ENDPOINTS
POD_NETWORK=10.0.10.0
ETCD_SERVER=http://192.168.56.101:4001
curl -X PUT -d "value={\"Network\":\"$POD_NETWORK\",\"Backend\":{\"Type\":\"vxlan\"}}" "$ETCD_SERVER/v2/keys/coreos.com/network/config"

# Start kubelet
sudo systemctl start kubelet
sudo systemctl enable kubelet

