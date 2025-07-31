#!/bin/bash
# Check status of all LLM services
# Author: Aman Dhingra

echo "📊 LLM Services Status"
echo "========================"

# Check system resources
echo "System Resources:"
echo "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "  Memory: $(free | awk 'NR==2{printf "%.1f/%.1fGB (%.1f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')"
echo "  Disk: $(df -h / | awk 'NR==2{printf "%s/%s (%s)", $3, $2, $5}')"
echo ""

# Check Ollama service
echo "Systemd Services:"
echo "----------------"
echo -n "Ollama Service: "
if systemctl is-active --quiet ollama; then
    echo "✅ Active"
    PID=$(systemctl show --property MainPID --value ollama)
    if [ "$PID" != "0" ]; then
        echo "  PID: $PID"
    fi
else
    echo "❌ Inactive"
fi

# Check FastAPI service
echo -n "FastAPI Service (llm-service): "
if [ -f /home/ec2-user/llm-service/fastapi.pid ]; then
    PID=$(cat /home/ec2-user/llm-service/fastapi.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ Active"
        echo "  PID: $PID"
    else
        echo "❌ Inactive (stale PID file)"
    fi
else
    echo "❌ Not started"
fi

echo ""

# Check port listeners
echo "Port Listeners:"
echo "----------------"
echo -n "FastAPI (Port 8000): "
if netstat -tuln 2>/dev/null | grep -q ":8000 " || ss -tuln 2>/dev/null | grep -q ":8000 "; then
    echo "✅ Running"
else
    echo "❌ Not listening"
fi

echo -n "Ollama (Port 11434): "
if netstat -tuln 2>/dev/null | grep -q ":11434 " || ss -tuln 2>/dev/null | grep -q ":11434 "; then
    echo "✅ Running"
else
    echo "❌ Not listening"
fi

echo ""

# API Health checks
echo "API Health Check:"
echo "----------------"
echo -n "API Health: "
if curl -s --max-time 5 http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Healthy"
    
    # Get Ollama connection status
    HEALTH_RESPONSE=$(curl -s --max-time 5 http://localhost:8000/health)
    if [ $? -eq 0 ]; then
        OLLAMA_STATUS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('ollama_status', 'unknown'))" 2>/dev/null || echo "unknown")
        MODELS=$(echo "$HEALTH_RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('available_models', [])))" 2>/dev/null || echo "0")
        echo "  Ollama Connection: $OLLAMA_STATUS"
        echo "  Available Models: $MODELS"
    fi
else
    echo "❌ Unhealthy"
fi

echo ""

# Get public IP for external access
PUBLIC_IP=$(curl -s --max-time 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$PUBLIC_IP" ]; then
    echo "🌐 Access URLs:"
    echo "FastAPI Backend: http://$PUBLIC_IP:8000"
    echo "API Documentation: http://$PUBLIC_IP:8000/docs"
    echo ""
fi

echo "📋 Service Management:"
echo "To start services: ./start_services.sh"
echo "To stop services: ./stop_services.sh"
echo "To view logs: sudo journalctl -u llm-service.service -f"
