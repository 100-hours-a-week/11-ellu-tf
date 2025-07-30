# Looper 서비스 IaC 리포지토리

## 📋 프로젝트 개요
이 프로젝트는 **Terraform**을 활용하여 단일 인스턴스 VM부터 복합적인 멀티클라우드 Kubernetes 클러스터까지 4단계에 걸친 Looper 서비스의 인프라 구축 과정을 담고 있습니다. 

해당 IaC는 클라우드 리소스 생성에 사용되었으며, 실제 애플리케이션 배포 및 일부 의존성 설치는 수동으로 진행되었습니다. 

## 🚀 아키텍처 버전 (최신순)

### ☸️ V4: 멀티클라우드 Kubernetes 클러스터
**`v4_aws_kubeadm/`**

[V4 Architecture Diagram](https://github.com/user-attachments/assets/b115561a-48c1-442a-9d40-f58f66c408c7)

V4는 AWS 기반의 프로덕션 레벨의 Kubernetes 클러스터로, EKS 대신 kubeadm을 사용한 자체 구축 클러스터입니다. 멀티클라우드 환경과 하이브리드 연결을 통해 복잡한 요구사항을 충족합니다.

#### 🔧 **EC2 Cluster** (`ec2-cluster/`)

**핵심 아키텍처:**
- **Multi-AZ 배포**: 2개 가용 영역에 걸친 고가용성 설계
- **Control Plane**: 단일 마스터 노드 (확장 가능한 구조)
- **Worker Nodes**: 다중 AZ 분산 배치로 장애 복구 능력 강화
- **전용 Kafka Node**: 메시징 시스템을 위한 독립 노드

**네트워킹 (VPC 모듈):**
```
├── Public Subnets (2 AZ)     # NAT Gateway, Load Balancer
├── Private K8s Subnets (2 AZ) # Kubernetes 노드
└── Private RDS Subnets (2 AZ) # 데이터베이스
```

**보안 (Security 모듈):**
- **Security Groups**: 계층별 네트워크 보안 규칙
- **IAM Roles**: External Secrets Operator를 위한 IRSA 설정
- **VPC Endpoint**: 프라이빗 통신을 위한 AWS 서비스 엔드포인트

**Kubernetes 노드 (k8s 모듈):**
- **kubeadm 기반**: 완전한 제어권을 가진 클러스터 구축
- **Container Runtime**: CRI-O 사용
- **CNI**: Calico 네트워크 플러그인
- **암호화된 스토리지**: EBS 볼륨 암호화

**데이터베이스 (RDS 모듈):**
- **Multi-AZ RDS**: 고가용성 관리형 데이터베이스
- **자동 백업**: 7일 보존 정책
- **암호화**: 저장 및 전송 중 데이터 암호화
- **서브넷 그룹**: 프라이빗 서브넷 격리

**로드 밸런싱 (NLB 모듈):**
- **Network Load Balancer**: Layer 4 로드 밸런싱
- **Target Groups**: Kubernetes NodePort 서비스 연결
- **SSL/TLS 종료**: ACM 인증서를 통한 HTTPS 지원
- **Route53 통합**: DNS 자동 관리

#### 🎮 **GPU Node** (`gpu-node/`)

**특화된 GPU 워크로드 지원:**
- **NVIDIA GPU 인스턴스**: p3, g4dn 인스턴스 타입 지원
- **GPU Operator**: Kubernetes GPU 스케줄링
- **CUDA 환경**: 컨테이너 기반 GPU 워크로드
- **리소스 격리**: GPU 전용 노드 풀

#### 🔐 **OpenVPN** (`open-vpn/`)

**보안 접근 게이트웨이:**
- **OpenVPN Server**: 안전한 클러스터 접근
- **클라이언트 인증서**: PKI 기반 인증 시스템
- **네트워크 라우팅**: VPC 내부 리소스 접근
- **로그 및 모니터링**: 접근 로그 추적

#### 🌐 **VPC Peering & S2S VPN** (`vpc-peering-s2s-vpn/`)

**하이브리드 클라우드 연결:**

**VPC Peering:**
- **AWS VPC 간 연결**: OpenVPN VPC와 Kubernetes VPC 피어링
- **라우팅 테이블**: 자동 경로 전파
- **보안 그룹**: 크로스 VPC 통신 규칙

**Site-to-Site VPN:**
- **AWS-GCP 연결**: IPSec VPN 터널
- **BGP 라우팅**: 동적 경로 학습
- **고가용성**: 이중화된 VPN 터널
- **암호화 통신**: AES-256 암호화
- **Pod-to-Pod 통신**: Calico CNI VXLAN Overlay

**네트워크 토폴로지:**
```
GCP VPC (10.0.0.0/16)
    ↕ Site-to-Site VPN
AWS K8s VPC (10.1.0.0/16)
    ↕ VPC Peering
AWS OpenVPN VPC (10.2.0.0/16)
```

### 🏢 V3: 3-Tier GCP Architecture
**`v3_gcp_3tier/`**

[V3 Architecture Diagram]
<img width="810" height="1007" alt="v3" src="https://github.com/user-attachments/assets/9b629533-e063-4007-bec3-a7d9d1dcb0cb" />

V3는 확장 가능하고 고가용성을 제공하는 3계층 웹 애플리케이션 아키텍처입니다. 모듈화된 설계를 통해 각 계층을 독립적으로 관리하고 확장할 수 있습니다.

**3-Tier 아키텍처 구성:**

#### **Presentation Tier (프레젠테이션 계층)**
- **Global Load Balancer**: HTTP(S) 로드 밸런서로 전 세계 트래픽 분산
- **SSL/TLS 인증서**: Google 관리형 SSL 인증서 자동 프로비저닝
- **CDN 통합**: Cloud CDN으로 정적 콘텐츠 가속화
- **Health Check**: 백엔드 서비스 상태 모니터링

#### **Application Tier (애플리케이션 계층)**
- **Instance Group Manager**: 자동 스케일링과 롤링 업데이트 지원
- **다중 AZ 배포**: 가용성 향상을 위한 여러 존 분산
- **Auto Scaling**: CPU 사용률 기반 자동 확장/축소
- **Private Subnet**: 보안을 위한 프라이빗 네트워크 배치
- **Cloud NAT**: 아웃바운드 인터넷 접근 제공

#### **Data Tier (데이터 계층)**
- **Compute Engine DB**: 커스텀 PostgreSQL 데이터베이스 & ChromaDB 서버
- **Persistent Disk**: 고성능 SSD 스토리지
- **백업 자동화**: Cloud Storage를 활용한 정기 백업
- **보안 격리**: 데이터베이스 전용 서브넷 분리

**모듈 구조:**
```
├── modules/
│   ├── network/         # VPC, 서브넷, Cloud NAT, 방화벽
│   ├── iam/             # Service Account, IAM 역할 및 권한
│   ├── database/        # 데이터베이스 인스턴스 및 백업
│   ├── application/     # 애플리케이션 서버 그룹
│   └── load_balancer/   # 로드 밸런서 및 Health Check
```

**보안 강화 기능:**
- **IAP (Identity-Aware Proxy)**: 제로 트러스트 SSH 접근
- **Private Google Access**: 프라이빗 IP로 Google 서비스 접근
- **최소 권한 IAM**: 각 계층별 필요 최소 권한 부여
- **네트워크 태그**: 세밀한 방화벽 규칙 적용

### 🖥️ V2: GPU 지원 GCP VM
**`v2_gcp_vm_gpu/`**

[V2 Architecture Diagram]
<img width="906" height="645" alt="v2" src="https://github.com/user-attachments/assets/8795e05a-a207-437d-80f7-7552386fb4b1" />

V2는 V1의 기본 구조를 유지하면서 GPU 가속 기능을 추가한 버전입니다. AI/ML 워크로드와 고성능 컴퓨팅이 필요한 애플리케이션을 위한 인프라를 제공합니다.

**V1 대비 주요 개선사항:**
- **NVIDIA L4 GPU**: 머신러닝 및 AI 워크로드 가속화
- **GPU 스케줄링 정책**: `on_host_maintenance = "TERMINATE"` 설정으로 GPU 워크로드 최적화
- **전용 머신 타입**: GPU를 지원하는 인스턴스 타입 선택
- **GPU 드라이버**: 시작 스크립트를 통한 NVIDIA 드라이버 자동 설치

**기술적 특징:**
- GPU 리소스 할당 및 관리
- CUDA 환경 자동 구성
- 비용 최적화를 위한 preemptible 인스턴스 옵션
- GPU 모니터링 및 사용률 추적

**사용 사례:**
- 딥러닝 모델 추론
- 임베딩 모델 사용

### 🎯 V1: 기본 GCP VM 구축
**`v1_gcp_vm/`**

[V1 Architecture Diagram]
<img width="906" height="645" alt="v1" src="https://github.com/user-attachments/assets/fc6d3069-683d-4de5-84bf-a08ebb23f5d3" />

V1은 Google Cloud Platform에서 가장 기본적인 단일 VM 인프라를 구축한 버전입니다.

**주요 구성 요소:**
- **Compute Engine 인스턴스**: 단일 VM으로 웹 애플리케이션 호스팅
- **VPC 네트워크**: 커스텀 VPC와 서브넷 생성으로 네트워크 격리
- **방화벽 규칙**: HTTP(80), HTTPS(443), SSH(22) 포트 허용
- **정적 IP 주소**: 외부 접근을 위한 고정 IP 할당
- **Service Account**: 최소 권한 원칙을 적용한 서비스 계정
- **DNS 연동**: Cloud DNS를 통한 도메인 연결
- **시작 스크립트**: 템플릿 파일을 통한 VM 초기 설정 자동화

## 🛠️ 기술 스택

| 카테고리 | 기술 스택 |
|---------|----------|
| **Infrastructure as Code** | Terraform, HCL |
| **Cloud Providers** | Google Cloud Platform, Amazon Web Services |
| **Container Orchestration** | Kubernetes (kubeadm)|
| **Networking** | VPC, VPC Peering, Site-to-Site VPN, Cloud NAT |
| **Load Balancing** | AWS Network Load Balancer, GCP HTTP(S) LB |
| **Security** | IAM, Security Groups, Service Accounts, IAP |
| **Database** | Amazon RDS (Multi-AZ), Redis (StatefulSet), ChromaDB (StatefulSet) |
| **Message Queue** | Apache Kafka (StatefulSet) |
| **Monitoring & Observability** | Prometheus, Grafana, Loki, Tempo, OpenTelemetry Collector |
| **DNS** | Cloud DNS, Route53 |
| **Storage** | Persistent Disk, EBS |

## 📈 진화 포인트

### 🔄 V4 → V3: 클라우드 네이티브 + 멀티클라우드
- **VM 기반** → **컨테이너 기반 (Kubernetes)**
- **단일 클라우드** → **멀티클라우드 하이브리드**
- **보안 접근**: OpenVPN을 통한 프라이빗 클러스터 접근
- 마이크로서비스 아키텍처 지원
- DevOps 및 GitOps 워크플로우 준비

### 🔄 V3 → V2: 엔터프라이즈 아키텍처
- **단일 인스턴스** → **3계층 아키텍처**
- 확장성과 가용성 대폭 향상
- 모듈화를 통한 코드 재사용성 확보
- 로드 밸런싱과 자동 스케일링 도입

### 🔄 V2 → V1: 고성능 컴퓨팅 지원
- **기본 VM** → **GPU 가속 VM**
- 머신러닝/AI 워크로드 지원 추가
- 고성능 컴퓨팅 환경 구축

## 🎯 주요 성취

### 🏗️ **Infrastructure as Code**
- 코드 기반 인프라 관리
- 환경별 변수 관리 및 재사용
- 모듈화를 통한 유지보수성 향상

### 🔒 **보안 모범 사례**
- 최소 권한 원칙 일관 적용
- 네트워크 계층별 보안 격리
- 암호화 통신 및 저장

### 📊 **고가용성 및 확장성**
- Multi-AZ 배포를 통한 장애 복구
- 자동 스케일링 및 로드 밸런싱
- 무중단 배포 지원

### 🌐 **멀티클라우드 아키텍처**
- AWS와 GCP 간 하이브리드 연결
- 클라우드 종속성 최소화
- 재해 복구 및 비즈니스 연속성

---
