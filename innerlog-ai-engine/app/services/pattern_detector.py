"""
Silent Coach pattern detection — hybrid approach:
  - 5 original threshold-based patterns (mood_drop, stress_spike, low_energy,
    missed_checkins, burnout_risk)
  - 4 new statistical patterns (mood_declining, mood_volatile, downtrend_signal,
    energy_mood_linked) using scipy + numpy
"""
from datetime import datetime
from typing import List

import numpy as np

# scipy is optional — graceful fallback if not installed
try:
    from scipy import stats as sp_stats
    HAS_SCIPY = True
except ImportError:
    HAS_SCIPY = False

ENERGY_MAP = {"low": 1, "normal": 2, "high": 3}


# ── Original threshold-based patterns ─────────────────────────────

def _pattern_mood_drop(moods: List[int]) -> List[dict]:
    """Mood dropping 3+ consecutive days."""
    consecutive = 0
    for i in range(1, len(moods)):
        if moods[i] < moods[i - 1]:
            consecutive += 1
        else:
            consecutive = 0
        if consecutive >= 2:
            return [{
                "type": "mood_drop",
                "message": "Tâm trạng giảm liên tục. Hãy dành thời gian cho bản thân.",
                "severity": "warning",
            }]
    return []


def _pattern_stress_spike(moods: List[int]) -> List[dict]:
    """Mood ≤ 2 for 2+ of last 5 days."""
    low_count = sum(1 for m in moods[-5:] if m <= 2)
    if low_count >= 2:
        return [{
            "type": "stress_spike",
            "message": "Bạn có vẻ đang stress. Thử nghỉ ngơi hoặc tập thể dục nhẹ.",
            "severity": "high",
        }]
    return []


def _pattern_low_energy(checkins: List[dict]) -> List[dict]:
    """Low energy 3+ of last 5 days."""
    energies = [c["energy_level"] for c in checkins]
    low_count = sum(1 for e in energies[-5:] if e == "low")
    if low_count >= 3:
        return [{
            "type": "low_energy",
            "message": "Năng lượng thấp nhiều ngày. Kiểm tra giấc ngủ và dinh dưỡng.",
            "severity": "warning",
        }]
    return []


def _pattern_missed_checkins(checkins: List[dict]) -> List[dict]:
    """Gap ≥ 3 days between check-ins."""
    if len(checkins) < 2:
        return []
    dates = []
    for c in checkins:
        try:
            raw = c["created_at"]
            if isinstance(raw, str):
                dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
            else:
                dt = raw
            dates.append(dt.date() if hasattr(dt, "date") else dt)
        except (ValueError, AttributeError, TypeError):
            pass
    if len(dates) < 2:
        return []
    dates.sort()
    max_gap = max((dates[i] - dates[i - 1]).days for i in range(1, len(dates)))
    if max_gap >= 3:
        return [{
            "type": "missed_checkins",
            "message": f"Bạn đã bỏ check-in {max_gap} ngày liên tiếp. Hãy quay lại nhé!",
            "severity": "info",
        }]
    return []


def _pattern_burnout_risk(checkins: List[dict]) -> List[dict]:
    """Low mood + low energy combo ≥ 3 of last 7 days."""
    recent = checkins[-7:] if len(checkins) >= 7 else checkins
    score = sum(
        1 for c in recent
        if c["mood_score"] <= 2 and c["energy_level"] == "low"
    )
    if score >= 3:
        return [{
            "type": "burnout_risk",
            "message": "Có dấu hiệu kiệt sức. Hãy cân bằng công việc và nghỉ ngơi.",
            "severity": "high",
        }]
    return []


# ── New statistical patterns (require scipy) ─────────────────────

def _pattern_mood_declining(moods_arr: np.ndarray) -> List[dict]:
    """Linear regression on mood — statistically significant decline."""
    if not HAS_SCIPY or len(moods_arr) < 5:
        return []
    x = np.arange(len(moods_arr))
    slope, _intercept, r_value, p_value, _stderr = sp_stats.linregress(x, moods_arr)
    if slope < -0.15 and p_value < 0.1:
        return [{
            "type": "mood_declining",
            "message": f"Tâm trạng có xu hướng giảm dần ({slope:.2f}/ngày). Hãy chú ý chăm sóc bản thân.",
            "severity": "warning",
            "confidence": round(abs(r_value), 2),
        }]
    return []


def _pattern_mood_volatile(moods_arr: np.ndarray) -> List[dict]:
    """High mood volatility in last 7 days."""
    if len(moods_arr) < 7:
        return []
    rolling_std = float(np.std(moods_arr[-7:]))
    if rolling_std > 1.2:
        return [{
            "type": "mood_volatile",
            "message": "Cảm xúc dao động nhiều trong tuần qua. Thử duy trì routine ổn định.",
            "severity": "info",
        }]
    return []


def _pattern_downtrend_signal(moods_arr: np.ndarray) -> List[dict]:
    """Short-term MA crosses below long-term MA (bearish crossover)."""
    if len(moods_arr) < 10:
        return []
    ma_short = np.convolve(moods_arr, np.ones(3) / 3, mode="valid")
    ma_long = np.convolve(moods_arr, np.ones(7) / 7, mode="valid")
    min_len = min(len(ma_short), len(ma_long))
    if min_len < 2:
        return []
    if ma_short[-1] < ma_long[-1] and ma_short[-2] >= ma_long[-2]:
        return [{
            "type": "downtrend_signal",
            "message": "Tâm trạng ngắn hạn đang thấp hơn trung bình. Đây có thể là giai đoạn khó khăn.",
            "severity": "warning",
        }]
    return []


def _pattern_energy_mood_linked(
    moods_arr: np.ndarray, energies_arr: np.ndarray
) -> List[dict]:
    """Strong Pearson correlation between mood and energy."""
    if not HAS_SCIPY or len(moods_arr) < 7:
        return []
    recent_m = moods_arr[-7:]
    recent_e = energies_arr[-7:]
    # Need variance in both arrays for correlation
    if np.std(recent_m) < 0.01 or np.std(recent_e) < 0.01:
        return []
    corr, _p = sp_stats.pearsonr(recent_m, recent_e)
    if corr > 0.7:
        return [{
            "type": "energy_mood_linked",
            "message": "Năng lượng và tâm trạng liên quan chặt chẽ. Cải thiện giấc ngủ có thể giúp mood tốt hơn.",
            "severity": "info",
        }]
    return []


# ── Main entry point ──────────────────────────────────────────────

def detect_patterns(checkins: List[dict]) -> List[dict]:
    """
    Silent Coach pattern detection.
    Runs all threshold-based patterns (min 3 checkins) +
    statistical patterns (min 5 checkins, requires scipy).
    """
    alerts: List[dict] = []
    if len(checkins) < 3:
        return alerts

    moods = [c["mood_score"] for c in checkins]

    # Threshold-based patterns (always run)
    alerts.extend(_pattern_mood_drop(moods))
    alerts.extend(_pattern_stress_spike(moods))
    alerts.extend(_pattern_low_energy(checkins))
    alerts.extend(_pattern_missed_checkins(checkins))
    alerts.extend(_pattern_burnout_risk(checkins))

    # Statistical patterns (need numpy arrays + more data)
    if len(checkins) >= 5:
        moods_arr = np.array(moods, dtype=float)
        energies_arr = np.array(
            [ENERGY_MAP.get(c["energy_level"], 2) for c in checkins], dtype=float
        )
        alerts.extend(_pattern_mood_declining(moods_arr))
        alerts.extend(_pattern_mood_volatile(moods_arr))
        alerts.extend(_pattern_downtrend_signal(moods_arr))
        alerts.extend(_pattern_energy_mood_linked(moods_arr, energies_arr))

    return alerts
