#!/bin/bash

# Install Kubernetes on CoreOS alpha


# Copy kube-controller-manager.yaml,kube-scheduler.yaml  into /srv/kubernetes/manifests
sudo mkdir /srv/kubernetes
sudo mkdir /srv/kubernetes/manifests
cp kube-controller-manager.yaml /srv/kubernetes/manifests
cp kuber-scheduler.yaml /srv/kubernetes/manifests