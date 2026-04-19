from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, List, Optional

import numpy as np

try:
    from scipy import stats as sp_stats
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False

router = APIRouter()

ENERGY_MAP = {"low": 1, "normal": 2, "high": 3}


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
    significant: bool
    p_value: Optional[float] = None
    mood_volatility_change: str
    energy_distribution: Dict[str, Dict[str, int]]


@router.post("/trend-compare", response_model=TrendResponse)
async def trend_compare(req: TrendRequest):
    p1 = [c.model_dump() for c in req.period1]
    p2 = [c.model_dump() for c in req.period2]

    m1 = np.array([c["mood_score"] for c in p1], dtype=float) if p1 else np.array([])
    m2 = np.array([c["mood_score"] for c in p2], dtype=float) if p2 else np.array([])

    avg1 = float(m1.mean()) if len(m1) > 0 else 0.0
    avg2 = float(m2.mean()) if len(m2) > 0 else 0.0
    mood_change = round(avg2 - avg1, 2)

    # Energy averages
    e1 = np.array([ENERGY_MAP.get(c["energy_level"], 2) for c in p1], dtype=float) if p1 else np.array([2.0])
    e2 = np.array([ENERGY_MAP.get(c["energy_level"], 2) for c in p2], dtype=float) if p2 else np.array([2.0])
    e_avg1 = float(e1.mean())
    e_avg2 = float(e2.mean())

    if e_avg2 > e_avg1 + 0.3:
        energy_change = "improved"
    elif e_avg2 < e_avg1 - 0.3:
        energy_change = "declined"
    else:
        energy_change = "stable"

    # Statistical significance (Welch's t-test)
    significant = False
    p_value = None
    if HAS_SCIPY and len(m1) >= 3 and len(m2) >= 3:
        _t_stat, p_val = sp_stats.ttest_ind(m1, m2, equal_var=False)
        p_value = round(float(p_val), 4)
        significant = p_val < 0.05

    # Mood volatility comparison
    std1 = float(m1.std()) if len(m1) > 1 else 0.0
    std2 = float(m2.std()) if len(m2) > 1 else 0.0
    if std2 > std1 + 0.3:
        mood_volatility_change = "increased"
    elif std2 < std1 - 0.3:
        mood_volatility_change = "decreased"
    else:
        mood_volatility_change = "stable"

    # Energy distribution per period
    def count_energy(checkins):
        dist = {"low": 0, "normal": 0, "high": 0}
        for c in checkins:
            lvl = c["energy_level"]
            if lvl in dist:
                dist[lvl] += 1
        return dist

    energy_distribution = {
        "period1": count_energy(p1),
        "period2": count_energy(p2),
    }

    # Summary
    sig_text = "Sự thay đổi có ý nghĩa thống kê." if significant else "Chưa đủ dữ liệu để kết luận chắc chắn."
    if mood_change > 0.5:
        summary = f"Tâm trạng cải thiện +{mood_change}. Năng lượng {energy_change}. {sig_text}"
    elif mood_change < -0.5:
        summary = f"Tâm trạng giảm {mood_change}. Cần chú ý chăm sóc bản thân. {sig_text}"
    else:
        summary = f"Tâm trạng ổn định. Năng lượng {energy_change}. {sig_text}"

    return TrendResponse(
        mood_change=mood_change,
        energy_change=energy_change,
        summary=summary,
        significant=significant,
        p_value=p_value,
        mood_volatility_change=mood_volatility_change,
        energy_distribution=energy_distribution,
    )
