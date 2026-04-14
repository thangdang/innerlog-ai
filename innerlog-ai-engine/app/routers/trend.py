from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Optional

router = APIRouter()


class TrendCheckin(BaseModel):
    mood_score: int
    energy_level: str
    text_note: Optional[str] = ""
    created_at: str


class TrendRequest(BaseModel):
    period1: List[TrendCheckin]
    period2: List[TrendCheckin]


class TrendResponse(BaseModel):
    mood_change: float
    energy_change: str
    summary: str


@router.post("/trend-compare", response_model=TrendResponse)
async def trend_compare(req: TrendRequest):
    p1 = [c.model_dump() for c in req.period1]
    p2 = [c.model_dump() for c in req.period2]

    avg1 = sum(c["mood_score"] for c in p1) / len(p1) if p1 else 0
    avg2 = sum(c["mood_score"] for c in p2) / len(p2) if p2 else 0
    mood_change = round(avg2 - avg1, 2)

    e_map = {"low": 1, "normal": 2, "high": 3}
    e1 = sum(e_map.get(c["energy_level"], 2) for c in p1) / len(p1) if p1 else 2
    e2 = sum(e_map.get(c["energy_level"], 2) for c in p2) / len(p2) if p2 else 2

    if e2 > e1 + 0.3:
        energy_change = "improved"
    elif e2 < e1 - 0.3:
        energy_change = "declined"
    else:
        energy_change = "stable"

    if mood_change > 0.5:
        summary = f"Tâm trạng cải thiện +{mood_change}. Năng lượng {energy_change}."
    elif mood_change < -0.5:
        summary = f"Tâm trạng giảm {mood_change}. Cần chú ý chăm sóc bản thân."
    else:
        summary = f"Tâm trạng ổn định. Năng lượng {energy_change}."

    return TrendResponse(mood_change=mood_change, energy_change=energy_change, summary=summary)
