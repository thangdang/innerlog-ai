from fastapi import FastAPI
from app.routers import analyze, coach, trend

app = FastAPI(title="InnerLog AI Engine", version="1.0.0")

app.include_router(analyze.router, prefix="/ai", tags=["analyze"])
app.include_router(coach.router, prefix="/ai", tags=["coach"])
app.include_router(trend.router, prefix="/ai", tags=["trend"])


@app.get("/health")
def health():
    engines = {
        "sentiment": "sentence-transformers",
        "clustering": "scikit-learn kmeans",
        "insight": "ollama llama3.1 + rule-based fallback",
        "coach": "pattern detection + rule engine",
    }
    return {"status": "ok", "service": "innerlog-ai-engine", "engines": engines}
