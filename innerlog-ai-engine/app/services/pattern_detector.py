from typing import List
from datetime import datetime, timedelta


def detect_patterns(checkins: List[dict]) -> List[dict]:
    """
    Silent Coach pattern detection.
    Detects: mood drop, stress spike, missed check-ins, work/life imbalance.
    """
    alerts = []
    if len(checkins) < 3:
        return alerts

    moods = [c["mood_score"] for c in checkins]

    # Pattern 1: Mood dropping 3+ consecutive days
    consecutive_drops = 0
    for i in range(1, len(moods)):
        if moods[i] < moods[i - 1]:
            consecutive_drops += 1
        else:
            consecutive_drops = 0
        if consecutive_drops >= 2:
            alerts.append({
                "type": "mood_drop",
                "message": "Tâm trạng giảm liên tục. Hãy dành thời gian cho bản thân.",
                "severity": "warning",
            })
            break

    # Pattern 2: Stress spike (mood <= 2 for 2+ days)
    low_mood_streak = sum(1 for m in moods[-5:] if m <= 2)
    if low_mood_streak >= 2:
        alerts.append({
            "type": "stress_spike",
            "message": "Bạn có vẻ đang stress. Thử nghỉ ngơi hoặc tập thể dục nhẹ.",
            "severity": "high",
        })

    # Pattern 3: Low energy streak
    energies = [c["energy_level"] for c in checkins]
    low_energy = sum(1 for e in energies[-5:] if e == "low")
    if low_energy >= 3:
        alerts.append({
            "type": "low_energy",
            "message": "Năng lượng thấp nhiều ngày. Kiểm tra giấc ngủ và dinh dưỡng.",
            "severity": "warning",
        })

    # Pattern 4: Missed check-ins (gaps in dates)
    if len(checkins) >= 2:
        dates = []
        for c in checkins:
            try:
                dt = datetime.fromisoformat(c["created_at"].replace("Z", "+00:00"))
                dates.append(dt.date())
            except (ValueError, AttributeError):
                pass
        if dates:
            dates.sort()
            max_gap = 0
            for i in range(1, len(dates)):
                gap = (dates[i] - dates[i - 1]).days
                if gap > max_gap:
                    max_gap = gap
            if max_gap >= 3:
                alerts.append({
                    "type": "missed_checkins",
                    "message": f"Bạn đã bỏ check-in {max_gap} ngày liên tiếp. Hãy quay lại nhé!",
                    "severity": "info",
                })

    # Pattern 5: Work/life imbalance (all low mood + low energy = burnout risk)
    recent = checkins[-7:] if len(checkins) >= 7 else checkins
    burnout_score = sum(1 for c in recent if c["mood_score"] <= 2 and c["energy_level"] == "low")
    if burnout_score >= 3:
        alerts.append({
            "type": "burnout_risk",
            "message": "Có dấu hiệu kiệt sức. Hãy cân bằng công việc và nghỉ ngơi.",
            "severity": "high",
        })

    return alerts
