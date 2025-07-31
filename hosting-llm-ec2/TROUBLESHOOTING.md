# Troubleshooting Guide

This guide covers the most common issues you'll encounter when setting up your LLM service on EC2.

## Table of Contents

- [Quick Health Check](#quick-health-check)
- [Common Issues](#common-issues)
  - [1. Ollama Service Won't Start](#1-ollama-service-wont-start)
  - [2. FastAPI Service Won't Start](#2-fastapi-service-wont-start)
  - [3. Model Download Fails](#3-model-download-fails)
  - [4. API Returns Errors](#4-api-returns-errors)
  - [5. Can't Connect from Outside EC2](#5-cant-connect-from-outside-ec2)
  - [6. Slow Performance](#6-slow-performance)
- [Instance Recommendations](#instance-recommendations)
- [When to Get Help](#when-to-get-help)
- [Prevention](#prevention)

## Quick Health Check

```bash
# Check overall system status
./check_status.sh

# Check if services are running
sudo systemctl status ollama
ps aux | grep python | grep app.py
```

## Common Issues

### 1. Ollama Service Won't Start

**Symptoms:** `./start_services.sh` fails at "Waiting for Ollama to be ready"

**Quick Fix:**
```bash
# Restart Ollama service
sudo systemctl stop ollama
sudo systemctl start ollama

# Check logs for errors
sudo journalctl -u ollama -f
```

**If that doesn't work:**
```bash
# Reinstall Ollama
curl -fsSL https://ollama.ai/install.sh | sh
sudo systemctl enable ollama
sudo systemctl start ollama
```

### 2. FastAPI Service Won't Start

**Symptoms:** `curl http://localhost:8000/health` returns connection refused

**Quick Fix:**
```bash
# Check if port 8000 is in use
sudo lsof -i :8000

# If something else is using it, kill the process
sudo kill -9 <PID>

# Restart services
./start_services.sh
```

**If dependencies are missing:**
```bash
pip3 install -r requirements.txt
mkdir -p logs
./start_services.sh
```

### 3. Model Download Fails

**Symptoms:** `ollama pull llama3.1:8b` hangs or fails

**Quick Fix:**
```bash
# Check disk space (need ~5GB free)
df -h

# If low on space, clean up
sudo yum clean all
docker system prune -f  # if you have Docker

# Retry model download
ollama pull llama3.1:8b
```

### 4. API Returns Errors

**Symptoms:** Health check or chat completion returns 500 errors

**Quick Fix:**
```bash
# Test Ollama directly
curl http://localhost:11434/api/tags

# If Ollama works, restart FastAPI
pkill -f "python3 app.py"
./start_services.sh

# Check logs for specific errors
tail -f logs/fastapi.log
```

### 5. Can't Connect from Outside EC2

**Symptoms:** Strands SDK or external tools can't reach your service

**Quick Fix:**
1. **Check AWS Security Group** - Ensure port 8000 is open to your IP
2. **Test external connection:**
   ```bash
   curl -X POST http://YOUR-EC2-IP:8000/health
   ```
3. **If still failing, check EC2 firewall:**
   ```bash
   sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
   ```

### 6. Slow Performance

**Symptoms:** Responses take >30 seconds, high CPU usage

**Quick Fix:**
- **Upgrade instance**: Move from t3.xlarge to m6a.2xlarge
- **Reduce load**: Lower max_tokens in requests
- **Check resources**: `htop` and `free -h`

## Instance Recommendations

- **t3.xlarge**: Basic testing only
- **m6a.2xlarge**: Recommended for agentic applications  
- **Larger instances**: If you see consistent high CPU/memory usage

## When to Get Help

If these solutions don't work:
1. Check the GitHub repository issues
2. Include output from `./check_status.sh` when asking for help
3. Consider using Amazon Bedrock for production workloads

## Prevention

```bash
# Weekly maintenance
./check_status.sh
df -h  # Check disk space

# Monthly updates
sudo yum update -y
```

Remember: This setup is for learning and experimentation. For production, use managed services like Amazon Bedrock.
