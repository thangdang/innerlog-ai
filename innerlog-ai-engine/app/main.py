import logging
import os

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import analyze, coach, trend
from app.services.model_loader import is_model_loaded

load_dotenv()

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="InnerLog AI Engine", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(analyze.router, prefix="/ai", tags=["analyze"])
app.include_router(coach.router, prefix="/ai", tags=["coach"])
app.include_router(trend.router, prefix="/ai", tags=["trend"])

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")


@app.get("/health")
async def health():
    # Check Ollama availability
    ollama_ok = False
    try:
        async with httpx.AsyncClient(timeout=2) as client:
            resp = await client.get(f"{OLLAMA_URL}/api/tags")
            ollama_ok = resp.status_code == 200
    except Exception:
        pass

    return {
        "status": "ok",
        "service": "innerlog-ai-engine",
        "version": "2.0.0",
        "model_loaded": is_model_loaded(),
        "ollama_available": ollama_ok,
        "engines": {
            "sentiment": "sentence-transformers (hybrid: text NLP + mood)",
            "clustering": "KMeans embeddings + keyword fallback",
            "insight": "Ollama LLM + rule-based fallback",
            "coach": "statistical + threshold pattern detection",
        },
    }
