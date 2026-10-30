# Tericsoft Technologies - DevOps Internship Task

> **Containerized Web Application Deployment on AWS EC2 & ECS**  
> Reachable publicly at `http://<EC2-PUBLIC-IP>:8081`

---

## 📋 Overview

This repository contains the source code, containerization configuration, and deployment scripts for the DevOps Intern hands-on assessment at **Tericsoft Technologies**.

The application is a lightweight, production-grade Python web service served via Gunicorn inside an isolated Docker container, configured to expose port **8081** and deployed to AWS.

### Architectural Highlights
- **Application**: Lightweight Python Flask service with `/health` and live runtime metrics UI.
- **Production Server**: Gunicorn WSGI binding to `0.0.0.0:8081`.
- **Security & Best Practices**:
  - Non-root user execution (`appuser`).
  - Minimal image footprint based on `python:3.11-slim`.
  - Built-in Docker `HEALTHCHECK`.
  - Layer caching optimization in `Dockerfile`.
- **Cloud Infrastructure**:
  - **AWS EC2**: `t2.micro` (1 vCPU, 1 GB RAM, 8 GB gp3 disk, Ubuntu 24.04 LTS).
  - **AWS ECS (Bonus)**: Amazon ECS with AWS Fargate task definition exposing port 8081.

---

## 🖥️ Server Specifications & Justification

### Instance Type: `t2.micro` (AWS Free Tier Eligible)
- **vCPU**: 1
- **RAM**: 1 GB
- **Disk**: 8 GB General Purpose SSD (`gp3`)
- **OS**: Ubuntu 24.04 LTS

### Why this size was chosen:
1. **Workload Footprint**: The application is a lightweight containerized web server. At idle, the OS consumes ~180MB RAM and the containerized app consumes ~45MB RAM, comfortably staying within the 1GB threshold without paging or memory pressure.
2. **Cost Optimization**: Fits 100% inside the **AWS Free Tier** (750 hours/month of `t2.micro`), ensuring zero accidental cloud expenditure during evaluation.
3. **Burstable Performance**: The `t2.micro` burst credits easily handle burst spikes during Docker builds and package installations.

---

## 🚀 Quick Start (Local Development)

### 1. Prerequisites
- Docker & Docker Compose installed locally.

### 2. Build and Run via Docker
```bash
# Build the Docker image
docker build -t tericsoft-devops-app:latest .

# Run container mapping host port 8081 to container port 8081
docker run -d -p 8081:8081 --name tericsoft-app --restart unless-stopped tericsoft-devops-app:latest

# Check status
docker ps

# Verify in browser or via curl
curl http://localhost:8081/health
```

Or using Docker Compose:
```bash
docker compose up -d --build
```

---

## ☁️ AWS EC2 Deployment Guide

### Step 1: Provision EC2 Instance
1. Log in to AWS Management Console and open **EC2**.
2. Click **Launch Instance**:
   - **Name**: `tericsoft-devops-ec2`
   - **AMI**: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
   - **Instance Type**: `t2.micro` (Free tier eligible)
   - **Key Pair**: Select or create an SSH key pair (`.pem`)
3. **Network Settings (Security Group)**:
   - Configure Security Group Rules:
     - **Rule 1**: Type `SSH`, Port `22`, Source `My IP` (security best practice)
     - **Rule 2**: Type `Custom TCP`, Port `8081`, Source `0.0.0.0/0` (Anywhere IPv4 - required for public access)
4. Click **Launch Instance**.

### Step 2: Connect & Setup Environment
Connect via SSH:
```bash
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>
```

Run the automated setup script or execute manually:
```bash
# Update and install Docker
sudo apt-get update -y
sudo apt-get install -y docker.io git

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group (avoids needing sudo for docker commands)
sudo usermod -aG docker $USER
newgrp docker
```

### Step 3: Clone, Build, and Deploy
```bash
# Clone the repository
git clone https://github.com/<YOUR-USERNAME>/<YOUR-REPO-NAME>.git
cd <YOUR-REPO-NAME>

# Build the container
docker build -t tericsoft-devops-app .

# Run container exposing port 8081
docker run -d -p 8081:8081 --name tericsoft-app --restart unless-stopped tericsoft-devops-app
```

### Step 4: Verify Deployment
Open your browser and navigate to:
```
http://<EC2-PUBLIC-IP>:8081
```

---

## 🌟 Bonus: AWS ECS Deployment (Fargate)

Deploying on Amazon ECS (Elastic Container Service) with AWS Fargate provides serverless container management, automated restarts, and zero host management.

### Deployment Flow:
1. **ECR (Elastic Container Registry)**:
   - Create a private repository named `tericsoft-app`.
   - Authenticate Docker CLI and push the image:
     ```bash
     aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
     docker tag tericsoft-devops-app:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/tericsoft-app:latest
     docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/tericsoft-app:latest
     ```
2. **ECS Cluster**:
   - Create a cluster using **AWS Fargate (Serverless)**.
3. **ECS Task Definition**:
   - Launch type: **AWS Fargate**
   - OS/Architecture: Linux/X86_64
   - CPU: `0.25 vCPU`, Memory: `0.5 GB`
   - Container Image: ECR Image URI
   - Port Mapping: `8081` (TCP)
4. **ECS Service**:
   - Create Service in the cluster with Desired tasks = 1.
   - Networking: Public Subnet with **Public IP enabled**.
   - Security Group: Allow Inbound Custom TCP on port `8081` from `0.0.0.0/0`.
5. **Access**:
   - Navigate to the running ECS Task -> Copy Public IP -> Visit `http://<ECS-TASK-PUBLIC-IP>:8081`.

---

## 🛠️ Problems Faced & Resolutions

1. **Docker Daemon Socket Permission (`permission denied`):**
   - *Problem*: Running `docker ps` immediately after install failed with socket permission errors for the unprivileged `ubuntu` user.
   - *Fix*: Added the user to the `docker` group (`sudo usermod -aG docker $USER`) and refreshed group session with `newgrp docker`.

2. **Public Unreachability on Port 8081:**
   - *Problem*: The app was accessible via `curl localhost:8081` locally on the server, but browser requests from the outside timed out.
   - *Fix*: The EC2 security group only had Port 22 open by default. Added an inbound rule for Custom TCP port `8081` with source `0.0.0.0/0`.

3. **Loopback Address Binding in Container:**
   - *Problem*: Standard dev servers default to binding on `127.0.0.1`, which prevents external traffic through Docker port forwarding.
   - *Fix*: Explicitly configured Gunicorn to bind to `0.0.0.0:8081` inside the container.

---

## 📂 Repository Structure

```
├── app.py                  # Core Flask web application
├── templates/
│   └── index.html          # Responsive landing dashboard
├── Dockerfile              # Multi-stage/hardened Dockerfile (port 8081)
├── docker-compose.yml      # Local orchestration configuration
├── requirements.txt        # Python dependencies (Flask, Gunicorn)
├── setup-ec2.sh            # Automated EC2 setup script
├── .dockerignore           # Docker build exclusions
├── .gitignore              # Git ignore rules
└── README.md               # Complete documentation
```
