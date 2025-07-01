# 🤖 LLM Cluster Deployment on AWS EKS

This project sets up a scalable LLM (Large Language Model) inference infrastructure on **Amazon EKS** using CPU-based instances — with a clear path to upgrade for GPU acceleration.

---

## 📌 Overview

The deployment architecture includes:

- 🧠 **Ollama** – Model serving via StatefulSet (2 replicas)
- 🌐 **Open Web UI** – Frontend interface for interaction
- 🔀 **Nginx LLM Router** – For intelligent request routing and rate limiting
- ☁️ **AWS EKS Cluster** – With auto-scaling node groups (On-demand & Spot)
- 💾 **Persistent Storage** – For model weights
- 📊 **Monitoring & Logging Infrastructure**

---

## 🗺️ Architecture Diagram

## Architecture

```
                         +------------+
                         |   User     |
                         +------------+
                               |
                               v
                     +-------------------+
                     |   LLM Router      |
                     |   (Nginx)         |
                     +-------------------+
                       /             \
                      v               v
         +------------------+   +------------------+
         |  Open Web UI     |   |   Ollama API     |
         |  (Frontend)      |   |   (Model Server) |
         +------------------+   +------------------+
                  |                     |
                  v                     v
           +-------------+     +--------------------+
           |   Request   | --> | Model Inference    |
           |   Forward   |     | (Ollama Pod 1 & 2) |
           +-------------+     +--------------------+
                                        |
                                        v
                              +--------------------+
                              | Persistent Storage |
                              |   (PVC Volumes)    |
                              +--------------------+
```

Key Components:
1. **LLM Router**: Nginx reverse proxy handling load balancing
2. **Open Web UI**: User-friendly interface for model interaction
3. **Ollama API**: REST endpoint for model inference
4. **Stateful Pods**: Ollama instances with persistent model storage


⚙️ Prerequisites
✅ AWS Account with necessary permissions
✅ Terraform v1.0+
✅ AWS CLI configured (aws configure)
✅ kubectl configured
✅ helm installed

🚀 Deployment Steps
1️⃣ Infrastructure Provisioning
bash
Copy
Edit
cd terraform/
terraform init
terraform plan
terraform apply

2️⃣ Deploy Kubernetes Resources
kubectl apply -f storage-class.yaml
kubectl apply -f ollama-pvc.yaml
kubectl apply -f ollama-statefulset.yaml
kubectl apply -f openwebui-deployment.yaml
kubectl apply -f llm-router.yaml

🧩 Configuration Details
🛠 Terraform Modules
EKS Cluster: Kubernetes v1.33

Node Groups:

On-demand: 2 × c6a.8xlarge (32 vCPUs, 64GB RAM)
Spot: 2 × c6i.4xlarge / c6a.4xlarge (16 vCPUs, 32GB RAM)
Networking: VPC with public/private subnets across 3 AZs
Storage: 60GB gp2 volumes for model weights


🐳 Kubernetes Components
Component	Description
Ollama	StatefulSet, 2 replicas, anti-affinity rules
CPU: 6–8 cores, Memory: 12–16 GB
Open Web UI	Single replica + LoadBalancer service
LLM Router	Nginx with rate limiting (10 req/sec)


🧠 Default Model: llama3.1:8b

⚡ GPU Configuration (Theoretical Support)
To enable GPU support, update the following:

1️⃣ Terraform (eks.tf)
hcl
Copy
Edit
eks_managed_node_groups = {
  gpu_nodegroup = {
    name           = "gpu-nodegroup"
    instance_types = ["g5.2xlarge"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 2
    desired_size   = 1

    labels = {
      accelerator = "nvidia"
    }

    taints = [{
      key    = "nvidia.com/gpu"
      value  = "present"
      effect = "NO_SCHEDULE"
    }]
  }
}

2️⃣ Kubernetes Ollama Deployment Changes
Install NVIDIA plugin:

bash
Copy
Edit
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.1/nvidia-device-plugin.yml
Update Ollama container spec:

yaml
Copy
Edit
resources:
  limits:
    nvidia.com/gpu: 1
env:
  - name: CUDA_VISIBLE_DEVICES
    value: "all"

nodeSelector:
  accelerator: "nvidia"
tolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"


📈 Performance Benchmarks (CPU-only)
Model: llama3.1:8b
Prompt: "Explain quantum computing in one sentence."
Requests: 100 | Concurrency: 10

🔁 Test 1
📊 Results (N=100):
✅ Success Rate: 25.0%
⏱️ Latency (ms):
  - Avg: 16780.62
  - P50: 21698.38
  - P90: 30069.23
  - P99: 30118.89
  - Max: 30119.01

🔁 Test 2
📊 Results (N=100):
✅ Success Rate: 82.0%
⏱️ Latency (ms):
  - Avg: 21061.50
  - P50: 21554.29
  - P90: 30057.99
  - P99: 30115.88
  - Max: 30182.28

🔁 Test 3
📊 Results (N=100):
✅ Success Rate: 63.0%
⏱️ Latency (ms):
  - Avg: 21733.91
  - P50: 27783.08
  - P90: 30109.54
  - P99: 30138.11
  - Max: 30146.72


## 🧮 Estimated GPU Performance

| **Metric**        | **CPU (c6a.8xlarge)** | **GPU (g5.2xlarge – A10G)**     |
|-------------------|-----------------------|----------------------------------|
| Avg Latency       | ~16,780 ms            | ~839 ms                          |
| Throughput        | ~0.59 req/s           | ~11.91 req/s                     |
| Cost/hr           | ~$1.20                | ~$1.51                           |
| Energy Efficiency | 1x                    | ~15–20x                          |


🧯 Troubleshooting

❗ Model Not Loading
Check PVC storage usage
Ensure outbound internet access for model downloads

❗ High Latency
Scale Ollama replicas
Increase node size/resources

❗ GPU Issues
Confirm NVIDIA plugin status
Check for driver/device plugin logs

🚧 Known Limitations

Only CPU-based instances are used due to:
AWS GPU quota limits
High GPU cost
Additional driver complexity
Large models (>8B) are not supported without GPUs

🌟 Future Improvements
 Enable GPU-backed node group
 Autoscaling based on queue length
 Model cache & LRU strategy
 Prometheus/Grafana metrics dashboard

🎥 Video Demo
📽️ [[text](https://drive.google.com/file/d/1v-97KfXKRvpOTaDp5BEqhk28EtaHbjH5/view?usp=sharing)]

🙌 Contributions & Feedback
Have ideas to improve this project? Open an issue or submit a PR!

