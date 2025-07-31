#!/bin/bash
# Complete EC2 instance setup for LLM hosting
# Author: Aman Dhingra
# Usage: curl -fsSL https://raw.githubusercontent.com/your-username/medium-post-artifacts/main/hosting-llm-ec2/setup_instance.sh | bash

set -e

echo "🚀 Setting up LLM Service on EC2..."
echo "===================================="

# Update system packages
echo "📦 Updating system packages..."
sudo yum update -y

# Install Python 3.9 and pip
echo "🐍 Installing Python and development tools..."
sudo yum install -y python3 python3-pip git curl wget htop
sudo yum groupinstall -y "Development Tools"

# Install Ollama
echo "🦙 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Start and enable Ollama service
echo "🔧 Configuring Ollama service..."
sudo systemctl start ollama
sudo systemctl enable ollama

# Wait for Ollama to be ready
echo "⏳ Waiting for Ollama to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Ollama failed to start"
        exit 1
    fi
    sleep 2
done

# Download default model
echo "📥 Downloading Llama 3.1 8B model (this may take several minutes)..."
ollama pull llama3.1:8b

# Create project directory structure
echo "📁 Creating project structure..."
mkdir -p /home/ec2-user/llm-service/{logs,static}
cd /home/ec2-user/llm-service

# Download project files from GitHub
echo "📥 Downloading project files..."
REPO_BASE="https://raw.githubusercontent.com/your-username/medium-post-artifacts/main/hosting-llm-ec2"

curl -fsSL "$REPO_BASE/app.py" -o app.py
curl -fsSL "$REPO_BASE/requirements.txt" -o requirements.txt
curl -fsSL "$REPO_BASE/start_services.sh" -o start_services.sh
curl -fsSL "$REPO_BASE/stop_services.sh" -o stop_services.sh
curl -fsSL "$REPO_BASE/check_status.sh" -o check_status.sh
curl -fsSL "$REPO_BASE/test_api.sh" -o test_api.sh
curl -fsSL "$REPO_BASE/llm-service.service" -o llm-service.service

# Make scripts executable
chmod +x *.sh

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

# Create systemd service (optional)
echo "🔧 Setting up systemd service..."
sudo cp llm-service.service /etc/systemd/system/
sudo systemctl daemon-reload

echo ""
echo "✅ Setup completed successfully!"
echo ""
echo "🚀 Next steps:"
echo "1. Start services: ./start_services.sh"
echo "2. Check status: ./check_status.sh"
echo "3. Test API: ./test_api.sh"
echo ""
echo "🌐 Once started, access your API at:"
echo "  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo ""
echo "📚 For more information, see the README.md file"
