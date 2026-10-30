#!/usr/bin/env bash
# ==============================================================================
# Tericsoft Technologies - DevOps Task EC2 Setup & Deployment Script
# Automatically provisions Docker, builds container, and exposes port 8081
# Works on: Ubuntu 22.04 / 24.04 LTS and Amazon Linux 2023
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo " Starting Automated Docker Environment Setup on AWS EC2   "
echo "=========================================================="

# 1. Detect Distribution and Install Docker
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

echo "[1/4] Detected OS: $OS. Updating system & installing Docker..."

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg git
    
    # Official Docker apt repo
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
elif [ "$OS" = "amzn" ]; then
    sudo dnf update -y
    sudo dnf install -y docker git
else
    echo "Unknown OS, falling back to convenience script..."
    curl -fsSL https://get.docker.com | sh
fi

# 2. Start and enable Docker service
echo "[2/4] Starting and enabling Docker daemon..."
sudo systemctl start docker
sudo systemctl enable docker

# 3. Add current user to docker group to avoid sudo requirement
echo "[3/4] Configuring user permissions for Docker..."
sudo usermod -aG docker "$USER"

# 4. Verify Docker installation
echo "[4/4] Verifying Docker installation..."
sudo docker --version

echo "=========================================================="
echo " Docker installation completed successfully!             "
echo " To build and run the application manually:               "
echo "   docker build -t tericsoft-devops-app .                 "
echo "   docker run -d -p 8081:8081 --name my-app --restart unless-stopped tericsoft-devops-app"
echo "=========================================================="
