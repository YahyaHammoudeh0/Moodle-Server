"""
DeepSeek API Proxy
==================
A FastAPI application that proxies requests to the DeepSeek API
with rate limiting, authentication, and optional educational context.

Endpoints:
- POST /v1/chat/completions - OpenAI-compatible chat endpoint
- GET /health - Health check endpoint
- GET /models - List available models
"""

import os
import time
import hashlib
from datetime import datetime
from typing import Optional

import httpx
import structlog
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel, Field
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

# ===========================================
# Configuration
# ===========================================
DEEPSEEK_API_KEY = os.environ.get("DEEPSEEK_API_KEY", "")
PROXY_API_KEY = os.environ.get("PROXY_API_KEY", "")
RATE_LIMIT_PER_MINUTE = int(os.environ.get("RATE_LIMIT_PER_MINUTE", "10"))
DEBUG = os.environ.get("DEBUG", "false").lower() == "true"
LOG_LEVEL = os.environ.get("LOG_LEVEL", "info")

DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"

# Educational system prompt (optional, can be customized)
EDUCATIONAL_SYSTEM_PROMPT = """You are an educational AI assistant helping students learn.
Please provide clear, pedagogical explanations. When solving problems:
1. Explain your reasoning step by step
2. Highlight key concepts
3. Encourage understanding over memorization
4. Be patient and supportive"""

# ===========================================
# Logging Setup
# ===========================================
structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.add_log_level,
        structlog.processors.JSONRenderer() if not DEBUG else structlog.dev.ConsoleRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(
        structlog.stdlib._NAME_TO_LEVEL.get(LOG_LEVEL.upper(), 20)
    ),
)
logger = structlog.get_logger()

# ===========================================
# Rate Limiter
# ===========================================
limiter = Limiter(key_func=get_remote_address)

# ===========================================
# FastAPI App
# ===========================================
app = FastAPI(
    title="DeepSeek API Proxy",
    description="Educational platform proxy for DeepSeek API",
    version="1.0.0",
)

# Add rate limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===========================================
# Models
# ===========================================
class Message(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    model: str = Field(default="deepseek-chat")
    messages: list[Message]
    temperature: Optional[float] = Field(default=0.7, ge=0, le=2)
    max_tokens: Optional[int] = Field(default=2048, ge=1, le=8192)
    stream: Optional[bool] = Field(default=False)
    top_p: Optional[float] = Field(default=1.0, ge=0, le=1)
    frequency_penalty: Optional[float] = Field(default=0, ge=-2, le=2)
    presence_penalty: Optional[float] = Field(default=0, ge=-2, le=2)
    # Educational options
    add_educational_context: Optional[bool] = Field(default=False)


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    version: str


class ModelsResponse(BaseModel):
    object: str = "list"
    data: list[dict]


# ===========================================
# Authentication
# ===========================================
def verify_api_key(request: Request) -> str:
    """Verify the API key from the request."""
    auth_header = request.headers.get("Authorization", "")

    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Missing or invalid Authorization header. Use 'Bearer <api_key>'"
        )

    provided_key = auth_header[7:]  # Remove "Bearer " prefix

    # If no proxy API key is set, allow all requests (development mode)
    if not PROXY_API_KEY:
        logger.warning("No PROXY_API_KEY set - authentication disabled")
        return provided_key

    if provided_key != PROXY_API_KEY:
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )

    return provided_key


def anonymize_ip(ip: str) -> str:
    """Create a hashed version of IP for logging (privacy)."""
    return hashlib.sha256(ip.encode()).hexdigest()[:12]


# ===========================================
# Endpoints
# ===========================================
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.utcnow().isoformat(),
        version="1.0.0"
    )


@app.get("/models", response_model=ModelsResponse)
async def list_models(api_key: str = Depends(verify_api_key)):
    """List available models."""
    return ModelsResponse(
        data=[
            {
                "id": "deepseek-chat",
                "object": "model",
                "created": 1700000000,
                "owned_by": "deepseek"
            },
            {
                "id": "deepseek-coder",
                "object": "model",
                "created": 1700000000,
                "owned_by": "deepseek"
            }
        ]
    )


@app.post("/v1/chat/completions")
@limiter.limit(f"{RATE_LIMIT_PER_MINUTE}/minute")
async def chat_completions(
    request: Request,
    chat_request: ChatRequest,
    api_key: str = Depends(verify_api_key)
):
    """
    Proxy chat completions to DeepSeek API.
    OpenAI-compatible endpoint.
    """
    if not DEEPSEEK_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="DeepSeek API key not configured"
        )

    client_ip = get_remote_address(request)
    start_time = time.time()

    # Prepare messages
    messages = [{"role": m.role, "content": m.content} for m in chat_request.messages]

    # Optionally add educational context
    if chat_request.add_educational_context:
        # Prepend educational system prompt if not already present
        if not messages or messages[0].get("role") != "system":
            messages.insert(0, {"role": "system", "content": EDUCATIONAL_SYSTEM_PROMPT})

    # Prepare request to DeepSeek
    payload = {
        "model": chat_request.model,
        "messages": messages,
        "temperature": chat_request.temperature,
        "max_tokens": chat_request.max_tokens,
        "stream": chat_request.stream,
        "top_p": chat_request.top_p,
        "frequency_penalty": chat_request.frequency_penalty,
        "presence_penalty": chat_request.presence_penalty,
    }

    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json",
    }

    # Log request (anonymized)
    logger.info(
        "chat_request",
        client_hash=anonymize_ip(client_ip),
        model=chat_request.model,
        message_count=len(messages),
        stream=chat_request.stream,
    )

    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            if chat_request.stream:
                # Streaming response
                async def stream_response():
                    async with client.stream(
                        "POST",
                        DEEPSEEK_API_URL,
                        json=payload,
                        headers=headers,
                    ) as response:
                        if response.status_code != 200:
                            error_text = await response.aread()
                            logger.error(
                                "deepseek_error",
                                status_code=response.status_code,
                                error=error_text.decode()
                            )
                            yield f"data: {{'error': 'DeepSeek API error: {response.status_code}'}}\n\n"
                            return

                        async for chunk in response.aiter_bytes():
                            yield chunk

                return StreamingResponse(
                    stream_response(),
                    media_type="text/event-stream",
                    headers={
                        "Cache-Control": "no-cache",
                        "Connection": "keep-alive",
                    }
                )
            else:
                # Non-streaming response
                response = await client.post(
                    DEEPSEEK_API_URL,
                    json=payload,
                    headers=headers,
                )

                elapsed = time.time() - start_time

                if response.status_code != 200:
                    logger.error(
                        "deepseek_error",
                        status_code=response.status_code,
                        error=response.text,
                        elapsed=elapsed
                    )
                    raise HTTPException(
                        status_code=response.status_code,
                        detail=f"DeepSeek API error: {response.text}"
                    )

                result = response.json()

                # Log successful response (anonymized)
                logger.info(
                    "chat_response",
                    client_hash=anonymize_ip(client_ip),
                    model=chat_request.model,
                    tokens_prompt=result.get("usage", {}).get("prompt_tokens", 0),
                    tokens_completion=result.get("usage", {}).get("completion_tokens", 0),
                    elapsed=round(elapsed, 2)
                )

                return JSONResponse(content=result)

    except httpx.TimeoutException:
        logger.error("deepseek_timeout", elapsed=time.time() - start_time)
        raise HTTPException(
            status_code=504,
            detail="Request to DeepSeek API timed out"
        )
    except httpx.RequestError as e:
        logger.error("deepseek_connection_error", error=str(e))
        raise HTTPException(
            status_code=502,
            detail=f"Failed to connect to DeepSeek API: {str(e)}"
        )


# ===========================================
# Startup/Shutdown Events
# ===========================================
@app.on_event("startup")
async def startup_event():
    """Log startup information."""
    logger.info(
        "server_starting",
        rate_limit=f"{RATE_LIMIT_PER_MINUTE}/minute",
        debug=DEBUG,
        api_key_configured=bool(DEEPSEEK_API_KEY),
        proxy_auth_enabled=bool(PROXY_API_KEY)
    )


@app.on_event("shutdown")
async def shutdown_event():
    """Log shutdown."""
    logger.info("server_shutting_down")


# ===========================================
# Main Entry Point
# ===========================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
