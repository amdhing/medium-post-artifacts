#!/usr/bin/env python3
"""
LLM Service with FastAPI and Ollama Integration
Designed for compatibility with Strands SDK OllamaModel

This service provides a proxy to Ollama's native /api/chat endpoint
while adding production features like health checks and monitoring.
Fixed to handle tool calls properly.

Author: Aman Dhingra
License: MIT
"""

import asyncio
import json
import logging
import time
from datetime import datetime
from typing import Dict, List, Optional, Any, Union

import httpx
import uvicorn
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/home/ec2-user/llm-service/logs/app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Configuration
OLLAMA_BASE_URL = "http://localhost:11434"
DEFAULT_MODEL = "llama3.1:8b"
REQUEST_TIMEOUT = 720  # 12 minutes

# Pydantic Models - Compatible with Strands SDK and Ollama tool calls
class ToolCall(BaseModel):
    """Tool call structure for function calling."""
    function: Dict[str, Any] = Field(..., description="Function call details")

class ChatMessage(BaseModel):
    """
    Chat message that can handle both regular content and tool calls.
    This is compatible with Strands SDK tool calling patterns.
    """
    role: str = Field(..., description="Role of the message sender")
    content: Optional[str] = Field(default=None, description="Content of the message")
    tool_calls: Optional[List[ToolCall]] = Field(default=None, description="Tool calls made by assistant")
    
    # Ensure at least one of content or tool_calls is present
    def __init__(self, **data):
        super().__init__(**data)
        if not self.content and not self.tool_calls:
            # If neither is provided, set empty content to avoid validation errors
            self.content = ""

class ChatRequest(BaseModel):
    """
    Chat request format compatible with both Strands SDK and Ollama.
    This matches the format that Strands OllamaModel sends, including tool calls.
    """
    messages: List[ChatMessage] = Field(..., description="List of chat messages")
    model: str = Field(default=DEFAULT_MODEL, description="Model to use")
    stream: Optional[bool] = Field(default=False, description="Whether to stream response")
    # Additional Ollama-specific parameters
    options: Optional[Dict[str, Any]] = Field(default=None, description="Ollama options")
    tools: Optional[List[Dict[str, Any]]] = Field(default=None, description="Available tools")
    keep_alive: Optional[str] = Field(default=None, description="Keep alive duration")

class HealthResponse(BaseModel):
    status: str
    timestamp: str
    ollama_status: str
    available_models: List[str]

# Initialize FastAPI app
app = FastAPI(
    title="LLM Service - Strands SDK Compatible",
    description="Production-ready LLM service compatible with Strands SDK OllamaModel and tool calling",
    version="1.0.1",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# HTTP client for Ollama communication
http_client = httpx.AsyncClient(timeout=REQUEST_TIMEOUT)

async def check_ollama_health() -> Dict[str, Any]:
    """Check if Ollama service is running and get available models."""
    try:
        response = await http_client.get(f"{OLLAMA_BASE_URL}/api/tags")
        if response.status_code == 200:
            models_data = response.json()
            models = [model["name"] for model in models_data.get("models", [])]
            return {"status": "healthy", "models": models}
        else:
            return {"status": "unhealthy", "models": []}
    except Exception as e:
        logger.error(f"Ollama health check failed: {e}")
        return {"status": "unhealthy", "models": []}

def format_message_for_ollama(message: ChatMessage) -> Dict[str, Any]:
    """
    Format a ChatMessage for Ollama, handling both content and tool calls.
    """
    ollama_message = {"role": message.role}
    
    if message.content:
        ollama_message["content"] = message.content
    
    if message.tool_calls:
        # Convert tool calls to Ollama format
        ollama_message["tool_calls"] = []
        for tool_call in message.tool_calls:
            ollama_message["tool_calls"].append({
                "function": tool_call.function
            })
    
    # If neither content nor tool_calls, provide empty content
    if not message.content and not message.tool_calls:
        ollama_message["content"] = ""
    
    return ollama_message

@app.get("/", tags=["General"])
async def root():
    """Root endpoint with service information."""
    return {
        "service": "LLM Service - Strands SDK Compatible",
        "version": "1.0.1",
        "status": "running",
        "timestamp": datetime.utcnow().isoformat(),
        "compatibility": "Strands SDK OllamaModel with tool calling support",
        "endpoints": {
            "health": "/health",
            "chat": "/api/chat",
            "models": "/api/models",
            "docs": "/docs"
        }
    }

@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Health check endpoint for monitoring and load balancers."""
    ollama_health = await check_ollama_health()
    
    return HealthResponse(
        status="healthy" if ollama_health["status"] == "healthy" else "degraded",
        timestamp=datetime.utcnow().isoformat(),
        ollama_status=ollama_health["status"],
        available_models=ollama_health["models"]
    )

@app.post("/api/chat", tags=["Chat"])
async def chat_completion(request: ChatRequest):
    """
    Chat completion endpoint compatible with Strands SDK OllamaModel.
    
    This endpoint proxies requests to Ollama's native /api/chat endpoint
    while preserving the exact format that Strands SDK expects, including
    proper handling of tool calls.
    
    The Strands OllamaModel will send requests in this exact format,
    and expects responses in Ollama's native streaming format.
    """
    try:
        logger.info(f"Processing chat request for model: {request.model}")
        logger.info(f"Request has {len(request.messages)} messages")
        
        # Log message types for debugging
        for i, msg in enumerate(request.messages):
            has_content = bool(msg.content)
            has_tools = bool(msg.tool_calls)
            logger.info(f"Message {i}: role={msg.role}, has_content={has_content}, has_tool_calls={has_tools}")
        
        start_time = time.time()

        # Prepare request for Ollama's /api/chat endpoint
        # Format messages properly for Ollama
        ollama_messages = []
        for message in request.messages:
            ollama_message = format_message_for_ollama(message)
            ollama_messages.append(ollama_message)
        
        ollama_request = {
            "model": request.model,
            "messages": ollama_messages,
            "stream": request.stream or False,
        }
        
        # Add optional parameters if provided
        if request.options:
            ollama_request["options"] = request.options
        if request.tools:
            ollama_request["tools"] = request.tools
        if request.keep_alive:
            ollama_request["keep_alive"] = request.keep_alive

        logger.debug(f"Forwarding request to Ollama: {json.dumps(ollama_request, indent=2)}")

        # Forward request to Ollama's /api/chat endpoint
        response = await http_client.post(
            f"{OLLAMA_BASE_URL}/api/chat",
            json=ollama_request,
            timeout=REQUEST_TIMEOUT
        )

        processing_time = time.time() - start_time
        logger.info(f"Request processed in {processing_time:.2f} seconds")

        if response.status_code != 200:
            logger.error(f"Ollama request failed: {response.status_code} - {response.text}")
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Ollama request failed: {response.text}"
            )

        # For streaming requests, return the stream
        if request.stream:
            async def stream_response():
                async for chunk in response.aiter_lines():
                    if chunk:
                        yield f"{chunk}\n"
            
            return StreamingResponse(
                stream_response(),
                media_type="application/x-ndjson"
            )
        
        # For non-streaming requests, return the JSON response directly
        # This preserves Ollama's exact response format
        ollama_response = response.json()
        logger.info(f"Ollama response received: {json.dumps(ollama_response, indent=2)}")
        return ollama_response

    except httpx.TimeoutException:
        logger.error("Request timeout occurred")
        raise HTTPException(
            status_code=504, 
            detail="Request timeout - the model is taking too long to respond"
        )
    except httpx.RequestError as e:
        logger.error(f"Request error: {e}")
        raise HTTPException(
            status_code=503, 
            detail="Unable to connect to Ollama service"
        )
    except Exception as e:
        logger.error(f"Chat completion error: {e}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@app.get("/api/models", tags=["Models"])
async def list_models():
    """List available models - proxies to Ollama's /api/tags endpoint."""
    try:
        response = await http_client.get(f"{OLLAMA_BASE_URL}/api/tags")
        if response.status_code == 200:
            return response.json()
        else:
            raise HTTPException(
                status_code=500, 
                detail=f"Failed to fetch models: {response.status_code}"
            )
    except httpx.RequestError as e:
        logger.error(f"Failed to connect to Ollama: {e}")
        raise HTTPException(
            status_code=503, 
            detail="Unable to connect to Ollama service"
        )
    except Exception as e:
        logger.error(f"List models error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/models/{model_name}", tags=["Models"])
async def get_model_info(model_name: str):
    """Get detailed information about a specific model."""
    try:
        response = await http_client.post(
            f"{OLLAMA_BASE_URL}/api/show",
            json={"name": model_name}
        )
        if response.status_code == 200:
            return response.json()
        elif response.status_code == 404:
            raise HTTPException(status_code=404, detail=f"Model '{model_name}' not found")
        else:
            raise HTTPException(
                status_code=500,
                detail=f"Failed to get model info: {response.status_code}"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get model info error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Additional Ollama-compatible endpoints that Strands SDK might use
@app.post("/api/generate", tags=["Ollama Compatibility"])
async def generate_completion(request: dict):
    """
    Legacy generate endpoint for backward compatibility.
    Proxies to Ollama's /api/generate endpoint.
    """
    try:
        response = await http_client.post(
            f"{OLLAMA_BASE_URL}/api/generate",
            json=request,
            timeout=REQUEST_TIMEOUT
        )
        
        if response.status_code != 200:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Ollama request failed: {response.text}"
            )
        
        return response.json()
        
    except Exception as e:
        logger.error(f"Generate completion error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize service on startup."""
    logger.info("LLM Service starting up...")
    logger.info("Service designed for Strands SDK OllamaModel compatibility with tool calling support")
    
    # Check if Ollama is available
    ollama_health = await check_ollama_health()
    if ollama_health["status"] == "healthy":
        logger.info(f"Ollama is healthy with {len(ollama_health['models'])} models available")
        logger.info("Ready to serve Strands SDK requests with tool calling support")
    else:
        logger.warning("Ollama service is not healthy - some endpoints may not work")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    logger.info("LLM Service shutting down...")
    await http_client.aclose()

if __name__ == "__main__":
    uvicorn.run(
        app, 
        host="0.0.0.0", 
        port=8000, 
        timeout_keep_alive=720,
        timeout_graceful_shutdown=720,
        log_level="info"
    )
