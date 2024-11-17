#!/bin/bash

set -e

echo "Starting Kubernetes installation..."

# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Step 1: Update and Install Required Packages
echo "Updating system and installing prerequisites..."
sudo yum update -y
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 curl jq

# Step 2: Disable Swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Step 3: Enable Kernel Modules and Sysctl Settings
echo "Configuring kernel modules and sysctl settings..."
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# Step 4: Install containerd
if ! command -v containerd &>/dev/null; then
    echo "Installing containerd..."
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y containerd.io
else
    echo "containerd is already installed."
fi

# Step 5: Configure containerd
echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

# Enable systemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
echo "Restarting containerd..."
sudo systemctl restart containerd
sudo systemctl enable containerd

# Step 6: Configure crictl
echo "Configuring crictl..."
sudo mkdir -p /etc
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

# Step 7: Add Kubernetes Repository
echo "Adding Kubernetes repository..."
# This overwrites any existing configuration in /etc/yum.repos.d/kubernetes.repo
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo yum update -y

# Step 8: Install Kubernetes Components
echo "Installing kubelet, kubeadm, and kubectl..."
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

# Step 9: Pull the Correct Pause Image
PAUSE_IMAGE="registry.k8s.io/pause:3.9"
echo "Pulling the pause image: $PAUSE_IMAGE..."
sudo crictl pull $PAUSE_IMAGE

# Step 10: Initialize Kubernetes Control Plane
read -p "Enter the API server advertise address (e.g., 10.2.0.4): " API_SERVER_ADDRESS
read -p "Enter the Pod Network CIDR (e.g., 192.168.0.0/16): " POD_NETWORK_CIDR

echo "Initializing Kubernetes cluster..."
sudo kubeadm init --apiserver-advertise-address $API_SERVER_ADDRESS --pod-network-cidr=$POD_NETWORK_CIDR

# Step 11: Configure kubectl for the Current User
echo "Setting up kubectl for the current user..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Step 12: Deploy Pod Network Add-On
echo "Deploying Calico as the pod network add-on..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml

# Step 13: Verify the Installation
echo "Verifying the Kubernetes cluster setup..."
kubectl get nodes
kubectl get pods -A

echo "Kubernetes installation completed successfully!"
