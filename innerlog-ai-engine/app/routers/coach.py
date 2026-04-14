from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Optional
from app.services.pattern_detector import detect_patterns

router = APIRouter()


class CoachCheckin(BaseModel):
    mood_score: int
    energy_level: str
    created_at: str


class CoachRequest(BaseModel):
    checkins: List[CoachCheckin]


class CoachAlert(BaseModel):
    type: str
    message: str
    severity: str


class CoachResponse(BaseModel):
    alerts: List[CoachAlert]
    should_notify: bool


@router.post("/coach", response_model=CoachResponse)
async def coach(req: CoachRequest):
    checkins = [c.model_dump() for c in req.checkins]
    alerts = detect_patterns(checkins)
    should_notify = len(alerts) > 0
    return CoachResponse(alerts=alerts, should_notify=should_notify)
