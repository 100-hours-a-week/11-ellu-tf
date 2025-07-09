#!/bin/bash
# 최신 버전의 kubectl 다운로드
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# kubectl 체크섬 파일 다운로드
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"


echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# kubectl 설치
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# kubectl 실행 권한 부여 및 경로 이동
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl

kubectl version --client

# swap 비활성화
sudo swapoff -a

# 부팅 시 로드할 모듈 설정 파일(.conf) 생성
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# 모듈 즉시 로드
sudo modprobe overlay
sudo modprobe br_netfilter

# 필요한 sysctl 설정값 구성 (재부팅 후에도 유지)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# sysctl 설정 적용
sudo sysctl --system

## CRI-O 런타임 설치
sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates gpg


sudo curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list


sudo apt-get update -y
sudo apt-get install -y cri-o

# CRI-O 서비스 활성화 및 시작
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

echo "CRI 런타임이 성공적으로 설치되었습니다"

# Kubernetes 저장소 추가 및 필수 패키지 설치
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list


sudo apt-get update -y
sudo apt-get install -y kubelet="1.33.0-*" kubectl="1.33.0-*" kubeadm="1.33.0-*"
sudo apt-get update -y
sudo apt-get install -y jq

# kubelet 서비스 활성화 및 시작
sudo systemctl enable --now kubelet
sudo systemctl start kubelet