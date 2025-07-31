#!/bin/bash
# Stop all LLM services
# Author: Aman Dhingra

echo "🛑 Stopping LLM Services..."

# Stop FastAPI service
if [ -f /home/ec2-user/llm-service/fastapi.pid ]; then
    PID=$(cat /home/ec2-user/llm-service/fastapi.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Stopping FastAPI service (PID: $PID)..."
        kill $PID
        
        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! ps -p $PID > /dev/null 2>&1; then
                break
            fi
            sleep 1
        done
        
        # Force kill if still running
        if ps -p $PID > /dev/null 2>&1; then
            echo "Force killing FastAPI service..."
            kill -9 $PID
        fi
        
        rm /home/ec2-user/llm-service/fastapi.pid
        echo "✅ FastAPI service stopped"
    else
        echo "FastAPI service was not running"
        rm /home/ec2-user/llm-service/fastapi.pid
    fi
else
    echo "FastAPI service PID file not found"
fi

# Stop Ollama service
echo "Stopping Ollama service..."
sudo systemctl stop ollama
echo "✅ Ollama service stopped"

echo ""
echo "✅ All services stopped successfully!"
