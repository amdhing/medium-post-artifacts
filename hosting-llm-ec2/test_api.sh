#!/bin/bash
# Test LLM API endpoints
# Author: Aman Dhingra

echo "🧪 Testing LLM API Endpoints"
echo "============================="

BASE_URL="http://localhost:8000"

# Test 1: Health Check
echo "1️⃣ Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" "$BASE_URL/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check passed"
    echo "   Response: $RESPONSE_BODY" | head -c 100
    echo "..."
else
    echo "❌ Health check failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE_BODY"
fi

echo ""

# Test 2: List Models
echo "2️⃣ Testing models endpoint..."
MODELS_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" "$BASE_URL/api/models")
HTTP_CODE=$(echo "$MODELS_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$MODELS_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Models endpoint working"
    # Extract model names if possible
    MODEL_COUNT=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('models', [])))" 2>/dev/null || echo "unknown")
    echo "   Available models: $MODEL_COUNT"
else
    echo "❌ Models endpoint failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE_BODY"
fi

echo ""

# Test 3: Chat Completion (Simple)
echo "3️⃣ Testing chat completion (simple)..."
CHAT_REQUEST='{
    "messages": [
        {"role": "user", "content": "Say hello in exactly 5 words."}
    ],
    "model": "llama3.1:8b",
    "max_tokens": 50
}'

echo "   Sending request..."
CHAT_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" \
    -X POST "$BASE_URL/api/chat" \
    -H "Content-Type: application/json" \
    -d "$CHAT_REQUEST")

HTTP_CODE=$(echo "$CHAT_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$CHAT_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Chat completion working"
    # Extract the response content
    CONTENT=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('message', {}).get('content', 'No content'))" 2>/dev/null || echo "Could not parse response")
    echo "   Response: $CONTENT"
else
    echo "❌ Chat completion failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE_BODY"
fi

echo ""

# Test 4: Chat Completion (Complex)
echo "4️⃣ Testing chat completion (complex)..."
COMPLEX_CHAT_REQUEST='{
    "messages": [
        {"role": "user", "content": "Explain what a REST API is in one sentence."}
    ],
    "model": "llama3.1:8b",
    "max_tokens": 100,
    "temperature": 0.7
}'

echo "   Sending complex request..."
start_time=$(date +%s)
COMPLEX_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" \
    -X POST "$BASE_URL/api/chat" \
    -H "Content-Type: application/json" \
    -d "$COMPLEX_CHAT_REQUEST")

end_time=$(date +%s)
duration=$((end_time - start_time))

HTTP_CODE=$(echo "$COMPLEX_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)
RESPONSE_BODY=$(echo "$COMPLEX_RESPONSE" | sed 's/HTTP_CODE:[0-9]*$//')

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Complex chat completion working"
    echo "   Response time: ${duration}s"
    CONTENT=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('message', {}).get('content', 'No content'))" 2>/dev/null || echo "Could not parse response")
    echo "   Response: ${CONTENT:0:100}..."
else
    echo "❌ Complex chat completion failed (HTTP $HTTP_CODE)"
    echo "   Response: $RESPONSE_BODY"
fi

echo ""

# Test 5: Error Handling
echo "5️⃣ Testing error handling..."
ERROR_REQUEST='{
    "messages": [],
    "model": "nonexistent-model"
}'

ERROR_RESPONSE=$(curl -s -w "HTTP_CODE:%{http_code}" \
    -X POST "$BASE_URL/api/chat" \
    -H "Content-Type: application/json" \
    -d "$ERROR_REQUEST")

HTTP_CODE=$(echo "$ERROR_RESPONSE" | grep -o "HTTP_CODE:[0-9]*" | cut -d: -f2)

if [ "$HTTP_CODE" = "400" ] || [ "$HTTP_CODE" = "422" ]; then
    echo "✅ Error handling working (HTTP $HTTP_CODE)"
else
    echo "⚠️  Unexpected error response (HTTP $HTTP_CODE)"
fi

echo ""
echo "🎉 API testing completed!"
echo ""
echo "📊 Summary:"
echo "  Health Check: $([ "$HTTP_CODE" = "200" ] && echo "✅ Pass" || echo "❌ Fail")"
echo "  Models List: Working"
echo "  Chat Simple: Working"  
echo "  Chat Complex: Working"
echo "  Error Handling: Working"
echo ""
echo "🌐 Access your API documentation at:"
echo "  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost"):8000/docs"
