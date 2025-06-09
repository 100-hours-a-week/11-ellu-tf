#!/bin/bash

# Complete setup script for application server
set -e

# Log everything
exec > >(tee /var/log/startup-script.log) 2>&1
echo "Starting application server setup at $(date)"

# Update system
echo "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install essential packages
echo "Installing essential packages..."
apt-get install -y curl wget git vim htop unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release jq tree net-tools

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install NVIDIA Docker for GPU support
echo "Installing NVIDIA Docker for GPU support..."
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
apt-get update -y
apt-get install -y nvidia-docker2

# Install gcloud
echo "Installing gcloud CLI..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt-get update -y
apt-get install -y google-cloud-cli

# Install Nginx
echo "Installing Nginx..."
apt-get install -y nginx

# Create application directories
echo "Creating application directories..."
mkdir -p /opt/looper/{data,logs,scripts,keys}
chmod 700 /opt/looper/keys

# Create nginx configuration
echo "Creating Nginx configuration..."
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name _;
        
        location /health {
            return 200 'OK';
            add_header Content-Type text/plain;
        }

        location /api/ {
            proxy_pass http://127.0.0.1:8080/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Prefix /api;
            proxy_cache_bypass $http_upgrade;
        }

        location / {
            proxy_pass http://127.0.0.1:3000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF

# Enable nginx
systemctl restart nginx && systemctl enable nginx

# Create environment template
echo "Creating environment file..."
cat > /opt/looper/.env << 'EOF'
# Production Environment Variables
PROJECT_ID=primeval-rain-460507-n3
GAR_LOCATION=asia-northeast3
GAR_NAME=looper
IMAGE_TAG=latest

# Database Configuration
POSTGRES_USER=looper
POSTGRES_PASSWORD=looperismylooper
POSTGRES_DB=looperdb_main_dev
SPRING_DATASOURCE_URL=jdbc:postgresql://${db_private_ip}:5432/looperdb_main_dev

# Database Server IP
DB_INSTANCE_IP=${db_private_ip}

# Frontend URLs  
NEXT_PUBLIC_API_URL=http://REPLACE_LB_IP/api
NEXT_PUBLIC_AI_URL=http://REPLACE_LB_IP:8000
EOF

# Create deployment scripts
echo "Creating deployment scripts..."
cat > /opt/looper/scripts/deploy.sh << 'EOF'
#!/bin/bash
set -e

cd /opt/looper

# Authenticate with GAR
gcloud auth configure-docker asia-northeast3-docker.pkg.dev

# Pull and start services
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d

# Clean up old images
docker image prune -f

echo "Deployment completed!"
EOF

cat > /opt/looper/scripts/status.sh << 'EOF'
#!/bin/bash
cd /opt/looper
echo "=== Docker Services ==="
docker-compose -f docker-compose.prod.yml ps
echo ""
echo "=== System Resources ==="
echo "Memory:"
free -h
echo "Disk:"
df -h /opt
echo ""
echo "=== Network ==="
netstat -tlnp | grep -E "(80|8080|3000)"
EOF

cat > /opt/looper/scripts/logs.sh << 'EOF'
#!/bin/bash
cd /opt/looper
if [ -z "$1" ]; then
    docker-compose -f docker-compose.prod.yml logs --tail=50 -f
else
    docker-compose -f docker-compose.prod.yml logs --tail=50 -f $1
fi
EOF

chmod +x /opt/looper/scripts/*.sh

# Create network
docker network create looper-network || true

# Add useful aliases to bashrc
cat >> /home/ubuntu/.bashrc << 'EOF'

# Looper aliases
alias looper-deploy='/opt/looper/scripts/deploy.sh'
alias looper-status='/opt/looper/scripts/status.sh'
alias looper-logs='/opt/looper/scripts/logs.sh'
alias looper-restart='cd /opt/looper && docker-compose -f docker-compose.prod.yml restart'
alias looper-stop='cd /opt/looper && docker-compose -f docker-compose.prod.yml stop'
alias looper-start='cd /opt/looper && docker-compose -f docker-compose.prod.yml start'
EOF

# Set ownership
chown -R ubuntu:ubuntu /opt/looper

# Restart docker for nvidia support
systemctl restart docker

echo "Application server setup completed at $(date)!"
echo "Rebooting for GPU driver activation..."

# 자동 재부팅으로 GPU 드라이버 활성화
reboot
