#!/bin/bash
# Start all LLM services
# Author: Aman Dhingra

set -e

echo "🚀 Starting LLM Services..."

# Create logs directory if it doesn't exist
mkdir -p /home/ec2-user/llm-service/logs

# Start Ollama service
echo "Starting Ollama service..."
sudo systemctl start ollama
sudo systemctl enable ollama

# Wait for Ollama to be ready
echo "Waiting for Ollama to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Ollama failed to start within 30 seconds"
        exit 1
    fi
    sleep 1
done

# Check if FastAPI is already running
if [ -f /home/ec2-user/llm-service/fastapi.pid ]; then
    PID=$(cat /home/ec2-user/llm-service/fastapi.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "FastAPI is already running (PID: $PID)"
    else
        rm /home/ec2-user/llm-service/fastapi.pid
    fi
fi

# Start FastAPI service if not running
if [ ! -f /home/ec2-user/llm-service/fastapi.pid ]; then
    echo "Starting FastAPI service..."
    cd /home/ec2-user/llm-service
    nohup python3 app.py > logs/fastapi.log 2>&1 &
    echo $! > fastapi.pid
    
    # Wait for FastAPI to be ready
    echo "Waiting for FastAPI to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:8000/health > /dev/null 2>&1; then
            echo "✅ FastAPI is ready"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ FastAPI failed to start within 30 seconds"
            exit 1
        fi
        sleep 1
    done
fi

echo ""
echo "✅ All services started successfully!"
echo ""
echo "🌐 Service URLs:"
echo "  FastAPI: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000"
echo "  API Docs: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/docs"
echo "  Health Check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000/health"
echo ""
echo "📋 Management Commands:"
echo "  Check status: ./check_status.sh"
echo "  Stop services: ./stop_services.sh"
echo "  View logs: tail -f logs/fastapi.log"
