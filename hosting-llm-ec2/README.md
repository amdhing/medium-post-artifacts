# Host Your Own Open-Source LLM on Amazon EC2

This directory contains all the code and scripts needed to deploy your own LLM service on AWS EC2 using Ollama and FastAPI.

**Requirements:**
- Python 3.10+ (required for AI framework compatibility)
- Amazon Linux 2 or similar
- EC2 instance with at least 8GB RAM

## Table of Contents

- [Files Overview](#files-overview)
- [Quick Setup](#quick-setup)
- [Manual Setup](#manual-setup)
  - [1. Install Dependencies](#1-install-dependencies)
  - [2. Install Ollama](#2-install-ollama)
  - [3. Deploy Application](#3-deploy-application)
  - [4. Start Services](#4-start-services)
- [API Endpoints](#api-endpoints)
  - [Health Check](#health-check)
  - [Chat Completion](#chat-completion)
  - [List Models](#list-models)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [Security Considerations](#security-considerations)
- [Next Steps](#next-steps)
- [Support](#support)

## Files Overview

- `app.py` - Main FastAPI application with LLM service endpoints
- `requirements.txt` - Python dependencies
- `start_services.sh` - Script to start all services
- `stop_services.sh` - Script to stop all services  
- `check_status.sh` - Script to check service status
- `llm-service.service` - Systemd service file for production deployment
- `setup_instance.sh` - Complete EC2 instance setup script
- `test_api.sh` - API testing script

## Quick Setup

1. **Launch EC2 Instance**
   - Instance type: t3.xlarge or larger
   - AMI: Amazon Linux 2
   - Security group: Allow ports 22, 8000

2. **Run Setup Script**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/your-username/medium-post-artifacts/main/hosting-llm-ec2/setup_instance.sh | bash
   ```

3. **Start Services**
   ```bash
   cd /home/ec2-user/llm-service
   ./start_services.sh
   ```

4. **Test API**
   ```bash
   ./test_api.sh
   ```

## Manual Setup

If you prefer manual setup, follow these steps:

### 1. Install Dependencies
```bash
# Update system
sudo yum update -y

# Install Python and development tools
sudo yum install -y python3 python3-pip git curl wget
sudo yum groupinstall -y "Development Tools"

# Install Python packages
pip3 install -r requirements.txt
```

### 2. Install Ollama
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
sudo systemctl start ollama
sudo systemctl enable ollama

# Download model
ollama pull llama3.1:8b
```

### 3. Deploy Application
```bash
# Create project directory
mkdir -p /home/ec2-user/llm-service/logs
cd /home/ec2-user/llm-service

# Copy application files
# (Copy app.py, requirements.txt, and scripts from this repository)

# Make scripts executable
chmod +x *.sh
```

### 4. Start Services
```bash
./start_services.sh
```

## API Endpoints

### Health Check
```bash
curl http://localhost:8000/health
```

### Chat Completion
```bash
curl -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [{"role": "user", "content": "Hello!"}],
    "model": "llama3.1:8b"
  }'
```

### List Models
```bash
curl http://localhost:8000/api/models
```

## Production Deployment

For production use:

1. **Install as systemd service**
   ```bash
   sudo cp llm-service.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable llm-service
   sudo systemctl start llm-service
   ```

2. **Configure security groups** to restrict access
3. **Set up SSL/TLS** with certificates
4. **Implement authentication** as needed
5. **Configure monitoring** and logging

## Troubleshooting

For common issues and solutions, see the comprehensive [Troubleshooting Guide](TROUBLESHOOTING.md).

Quick diagnostics:
```bash
# Check overall system status
./check_status.sh

# Check individual services
sudo systemctl status ollama
ps aux | grep python | grep app.py
```

## Cost Optimization

- Use **Reserved Instances** for predictable workloads
- Consider **Spot Instances** for development
- Monitor usage with **CloudWatch**
- Right-size instances based on actual usage

## Security Considerations

- Restrict security groups to necessary IPs
- Use IAM roles instead of access keys
- Enable CloudTrail for audit logging
- Regular security updates
- Consider VPC deployment for isolation

## Next Steps

Once your LLM service is running, check out the companion article on building applications with the Strands SDK: [Building AI Applications with Strands SDK and Tool Calling](../strands-sdk-tool-calling/)

## Support

For issues or questions:
- Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
- Review the main Medium article
- Open an issue in this repository
