#!/bin/bash
set -e

exec > >(tee /var/log/startup-script.log) 2>&1
echo "Starting GPU server setup at $(date)"

echo "Updating system packages..."
apt-get update
apt-get upgrade -y

echo "Installing basic utilities..."
apt-get install -y git curl wget build-essential software-properties-common

echo "Installing NVIDIA drivers for L4 GPU on Ubuntu 24.04..."

add-apt-repository -y ppa:graphics-drivers/ppa
apt-get update

echo "Installing NVIDIA driver package..."
apt-get install -y nvidia-driver-535 nvidia-utils-535

sleep 5

echo "Downloading CUDA installation package..."
cd /tmp

download_cuda() {
    local url="https://developer.download.nvidia.com/compute/cuda/12.1.0/local_installers/cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb"
    local output_file="cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb"
    
    rm -f "$${output_file}"
    
    for i in {1..3}; do
        echo "Download attempt $${i}/3..."
        if wget --progress=bar:force --timeout=600 --tries=1 --continue "$${url}" -O "$${output_file}"; then
            # Verify the download size (should be around 3GB)
            file_size=$(stat -c%s "$${output_file}")
            if [ "$${file_size}" -gt 2000000000 ]; then
                echo "Download completed successfully. File size: $${file_size} bytes"
                return 0
            else
                echo "Download file size is too small: $${file_size} bytes. Retrying..."
                rm -f "$${output_file}"
            fi
        else
            echo "Download failed on attempt $${i}. Retrying..."
            rm -f "$${output_file}"
        fi
        
        if [ $${i} -lt 3 ]; then
            sleep 10
        fi
    done
    
    echo "Failed to download CUDA after 3 attempts"
    return 1
}

if ! download_cuda; then
    echo "ERROR: Failed to download CUDA toolkit. Manual intervention required."
    exit 1
fi

echo "Installing CUDA toolkit..."
dpkg -i /tmp/cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb

cp /var/cuda-repo-ubuntu2204-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/

apt-get update

echo "Installing CUDA packages..."
DEBIAN_FRONTEND=noninteractive apt-get install -y cuda

echo "Configuring CUDA environment..."
echo 'export PATH=/usr/local/cuda/bin:$PATH' >> /etc/profile.d/cuda.sh
echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> /etc/profile.d/cuda.sh
chmod +x /etc/profile.d/cuda.sh

echo "Verifying GPU installation..."
nvidia-smi

echo "Configuring GPU settings..."
nvidia-smi -pm 1

nvidia-smi -c 0

touch /var/log/gpu-setup-complete

echo "GPU server setup completed successfully at $(date)"
echo "CUDA version: $(nvcc --version | grep release)"

rm -f /tmp/cuda-repo-ubuntu2204-12-1-local_12.1.0-530.30.02-1_amd64.deb

echo "Setup script finished. Logs available at /var/log/startup-script.log"