#!/bin/bash
set -e

exec > >(tee /var/log/startup-script.log) 2>&1
echo "Starting database server setup at $(date)"

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

echo "Setting up data disk..."
if [ -b "${data_disk_device}" ]; then
  # Check if disk is already formatted
  if ! blkid "${data_disk_device}" > /dev/null; then
    echo "Formatting data disk..."
    mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard "${data_disk_device}"
  fi
  
  mkdir -p "${data_mount_point}"
  
  echo "${data_disk_device} ${data_mount_point} ext4 discard,defaults,nofail 0 2" | tee -a /etc/fstab
  
  mount "${data_mount_point}"
  
  mkdir -p "${data_mount_point}/postgresql"
  mkdir -p "${data_mount_point}/chromadb"
  
  chmod 777 "${data_mount_point}/postgresql"
  chmod 777 "${data_mount_point}/chromadb"
fi


echo "Database server setup completed at $(date)"
echo "Docker is installed and data disk is mounted at ${data_mount_point}"
echo "Please set up PostgreSQL and ChromaDB manually using Docker."