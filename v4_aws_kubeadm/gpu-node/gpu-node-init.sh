#!/bin/bash
set -e

# 버전 설정
KUBERNETES_VERSION="1.33"
CRIO_VERSION="v1.33"
DEVICE_PLUGIN_VERSION="v0.17.1"

# kubectl 설치
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl kubectl.sha256

# 스왑 메모리 완전 비활성화
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 컨테이너 런타임 커널 모듈 로드
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 네트워크 설정 (브릿지 트래픽 처리)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 기본 패키지 설치
sudo apt-get update -y
sudo apt-get install -y software-properties-common curl apt-transport-https ca-certificates gpg jq

# CRI-O 컨테이너 런타임 설치
sudo curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

# conmon 심볼릭 링크 수정 (CRI-O 호환성 문제 해결)
if [ -e /usr/libexec/crio/conmon ]; then
  sudo ln -sf /usr/libexec/crio/conmon /usr/bin/conmon
else
  sudo apt-get install -y conmon || sudo apt-get install -y cri-o-runc
  [ -e /usr/libexec/crio/conmon ] && sudo ln -sf /usr/libexec/crio/conmon /usr/bin/conmon
fi

sudo systemctl daemon-reload
sudo systemctl enable crio --now

# 쿠버네티스 구성요소 설치
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet="${KUBERNETES_VERSION}.0-*" kubectl="${KUBERNETES_VERSION}.0-*" kubeadm="${KUBERNETES_VERSION}.0-*"
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

# NVIDIA 드라이버 자동 설치
sudo apt-get install -y ubuntu-drivers-common
sudo ubuntu-drivers autoinstall

# NVIDIA Container Toolkit 설치
# OS 정보 가져오기
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update -y
sudo apt-get install -y nvidia-container-toolkit

# CRI-O에서 NVIDIA 런타임 사용 설정
sudo nvidia-ctk runtime configure --runtime=crio --set-as-default --config=/etc/crio/crio.conf.d/99-nvidia.conf
sudo nvidia-ctk config --config-file /etc/nvidia-container-runtime/config.toml --set nvidia-container-runtime.runtimes="[\"crun\", \"docker-runc\", \"runc\"]" --in-place

# CRI-O 재시작
sudo systemctl restart crio

# 다음 단계:
# 1. nvidia-smi가 안 되면 재부팅 필요
# 2. 클러스터 조인: sudo kubeadm join ...
# 3. 디바이스 플러그인 배포: kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/$DEVICE_PLUGIN_VERSION/deployments/static/nvidia-device-plugin.yml