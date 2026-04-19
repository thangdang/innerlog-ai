from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Optional
from app.services.sentiment import analyze_sentiment
from app.services.clustering import cluster_topics
from app.services.insight_generator import generate_insight_bullets

router = APIRouter()


class CheckinInput(BaseModel):
    mood_score: int
    energy_level: str
    text_note: Optional[str] = ""
    created_at: str


class AnalyzeRequest(BaseModel):
    checkins: List[CheckinInput]


class AnalyzeResponse(BaseModel):
    bullets: List[str]
    metrics: dict


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze(req: AnalyzeRequest):
    checkins = [c.model_dump() for c in req.checkins]

    # Step 1: Sentiment analysis (sync — ML model)
    sentiments = analyze_sentiment(checkins)

    # Step 2: Topic clustering (sync — ML model)
    topics = cluster_topics(checkins)

    # Step 3: Generate insight bullets (async — may call Ollama LLM)
    bullets, metrics = await generate_insight_bullets(checkins, sentiments, topics)

    return AnalyzeResponse(bullets=bullets, metrics=metrics)
