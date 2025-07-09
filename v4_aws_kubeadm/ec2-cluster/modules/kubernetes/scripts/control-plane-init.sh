#!/bin/bash
# kubectl 최신 버전 다운로드
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# 체크섬 파일도 같이 받아서 무결성 검증
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"

echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# kubectl을 시스템 경로에 설치
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# 사용자 로컬 경로에도 복사해두기
chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl

kubectl version --client

# 스왑 메모리 비활성화 (쿠버네티스 필수 요구사항)
sudo swapoff -a

# 컨테이너 런타임에 필요한 커널 모듈 설정
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# 모듈 바로 로드
sudo modprobe overlay
sudo modprobe br_netfilter

# 네트워크 브릿지 및 포워딩 설정 (재부팅 후에도 유지)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# 설정 즉시 적용
sudo sysctl --system

# CRI-O 컨테이너 런타임 설치
sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates gpg

sudo curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

# CRI-O 서비스 실행
sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

echo "CRI 컨테이너 런타임 설치 완료"

# 쿠버네티스 패키지 저장소 추가
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet="1.33.0-*" kubectl="1.33.0-*" kubeadm="1.33.0-*"
sudo apt-get update -y
sudo apt-get install -y jq

# kubelet 서비스 시작
sudo systemctl enable --now kubelet
sudo systemctl start kubelet