#!/bin/bash
set -e

exec > >(tee /var/log/startup-script.log) 2>&1
echo "Starting application server setup at $(date)"

echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# basic utilities
echo "Installing basic utilities..."
apt-get install -y git curl wget build-essential software-properties-common

# Docker and Docker Compose
echo "Installing Docker..."
apt-get install -y apt-transport-https ca-certificates gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# NVIDIA drivers for GPU
echo "Installing NVIDIA drivers for GPU..."
add-apt-repository -y ppa:graphics-drivers/ppa
apt-get update
apt-get install -y nvidia-driver-535 nvidia-utils-535

# NVIDIA Docker support
echo "Installing NVIDIA Docker support..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update
apt-get install -y nvidia-docker2
systemctl restart docker

echo "Application server setup completed at $(date)"
echo "NVIDIA driver and Docker are installed."
echo "Please set up your containers manually."