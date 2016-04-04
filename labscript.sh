#!/bin/bash
set -e

# Number of ETC Hosts
export $ETCD_COUNT=3

export ETCD_DISCOVERY_KEY=$(curl https://discovery.etcd.io/new?size=3)


######################################################################

# awk this at some point 
# (gcloud compute images list | grep coreos | grep alpha)

# generate cloud-config files
cp template_cloud-config.yaml etcd-cloud-config.yaml
sed -i 's@DISCOVERY_KEY@'$ETCD_DISCOVERY_KEY'@g' etcd-cloud-config.yaml
sed -i 's@LOCKSMITH_GROUP@kubernetes-etcd@g' etcd-cloud-config.yaml
cp template_cloud-config.yaml master-cloud-config.yaml
sed -i 's@DISCOVERY_KEY@'$ETCD_DISCOVERY_KEY'@g' master-cloud-config.yaml
sed -i 's@LOCKSMITH_GROUP@kubernetes-master@g' master-cloud-config.yaml
cp template_cloud-config.yaml worker-cloud-config.yaml
sed -i 's@DISCOVERY_KEY@'$ETCD_DISCOVERY_KEY'@g' worker-cloud-config.yaml
sed -i 's@LOCKSMITH_GROUP@kubernetes-worker@g' worker-cloud-config.yaml


# create etcd cluster
gcloud compute instances create etcd1 etcd2 etcd3  \
   --image-project coreos-cloud \
   --image  coreos-alpha-1000-0-0-v20160328\
   --machine-type g1-small \
   --tags k8s-cluster,k8s-etcd \
   --metadata-from-file user-data=etcd-cloud-config.yaml

# create master nodes
gcloud compute instances create master  \
   --image-project coreos-cloud \
   --image  coreos-alpha-1000-0-0-v20160328\
   --machine-type g1-small \
   --tags k8s-cluster,k8s-master \
   --metadata-from-file user-data=master-cloud-config.yaml

# create worker nodes
gcloud compute instances create worker1 worker2 worker3  \
   --image-project coreos-cloud \
   --image  coreos-alpha-1000-0-0-v20160328\
   --boot-disk-size 200GB \
   --machine-type n1-standard-1 \
   --tags k8s-cluster,k8s-worker \
   --metadata-from-file user-data=worker-cloud-config.yaml

openssl genrsa -out worker1-worker-key.pem 2048
openssl req -new -key worker1-worker-key.pem -out  worker1-worker.csr -subj "/CN=worker2" -config worker1-openssl.cnf
openssl x509 -req -in worker1-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker1-worker.pem -days 365 -extensions v3_req -extfile worker1-openssl.cnf
openssl genrsa -out worker2-worker-key.pem 2048
openssl req -new -key worker2-worker-key.pem -out  worker2-worker.csr -subj "/CN=worker2" -config worker2-openssl.cnf
openssl x509 -req -in worker2-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker2-worker.pem -days 365 -extensions v3_req -extfile worker2-openssl.cnf
openssl genrsa -out worker3-worker-key.pem 2048
openssl req -new -key worker3-worker-key.pem -out  worker3-worker.csr -subj "/CN=worker3" -config worker3-openssl.cnf
openssl x509 -req -in worker3-worker.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out worker3-worker.pem -days 365 -extensions v3_req -extfile worker3-openssl.cnf
