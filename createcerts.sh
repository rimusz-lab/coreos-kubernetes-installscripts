#!/bin/bash
# master.sh

export K8S_SERVICE_IP=10.3.0.1
export MASTER_HOST=172.17.8.101
export WORKER_IP=172.17.8.101
export WORKER_FQDN=core-01

rm -r openssl 
mkdir openssl
cd openssl

openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=kube-ca"

function init_templates {
    local TEMPLATE=./openssl.cnf 
    [ -f $TEMPLATE ] || {
        echo "TEMPLATE: $TEMPLATE"        
        cat << EOF > $TEMPLATE
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = $K8S_SERVICE_IP
IP.2 = $MASTER_HOST
EOF
}

    local TEMPLATE=./worker-openssl.cnf 
    [ -f $TEMPLATE ] || {
        echo "TEMPLATE: $TEMPLATE"        
        cat << EOF > $TEMPLATE
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
IP.1 = $WORKER_IP
EOF
}
}

init_templates

openssl genrsa -out apiserver-key.pem 2048
openssl req -new -key apiserver-key.pem -out apiserver.csr -subj "/CN=kube-apiserver" -config openssl.cnf
openssl x509 -req -in apiserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out apiserver.pem -days 365 -extensions v3_req -extfile openssl.cnf
openssl genrsa -out $WORKER_FQDN-worker-key.pem 2048
WORKER_IP=${WORKER_IP} openssl req -new -key $WORKER_FQDN-worker-key.pem -out  $WORKER_FQDN-worker.csr -subj "/CN=$WORKER_FQDN" -config worker-openssl.cnf
WORKER_IP=${WORKER_IP} openssl x509 -req -in $WORKER_FQDN-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out $WORKER_FQDN-worker.pem -days 365 -extensions v3_req -extfile worker-openssl.cnf
openssl genrsa -out admin-key.pem 2048
openssl req -new -key admin-key.pem -out admin.csr -subj "/CN=kube-admin"
openssl x509 -req -in admin.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out admin.pem -days 365

sudo mkdir -p /etc/kubernetes/ssl
sudo cp ca.pem /etc/kubernetes/ssl/ca.pem
sudo cp apiserver.pem /etc/kubernetes/ssl/apiserver.pem
sudo cp apiserver-key.pem /etc/kubernetes/ssl/apiserver-key.pem
sudo chmod 600 /etc/kubernetes/ssl/*-key.pem
sudo chown root:root /etc/kubernetes/ssl/*-key.pem
cd ..

wget https://raw.githubusercontent.com/alekssaul/coreos-kubernetes-installscripts/master/controller-install.sh
wget https://raw.githubusercontent.com/alekssaul/coreos-kubernetes-installscripts/master/kubelet-wrapper
sudo mkdir -p /opt/bin
sudo cp kubelet-wrapper /opt/bin
sudo chmod +x ./controller-install.sh
sudo chmod +x /opt/bin/kubelet-wrapper