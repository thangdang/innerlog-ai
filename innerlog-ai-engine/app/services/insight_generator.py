from typing import List, Tuple


def generate_insight_bullets(
    checkins: List[dict],
    sentiments: List[dict],
    topics: List[str],
) -> Tuple[List[str], dict]:
    """
    Generate insight bullets (max 5, <=20 words each).
    Rule-based engine. Future: LLM summary via Ollama.
    """
    bullets = []
    n = len(checkins)
    if n == 0:
        return ["Chưa có dữ liệu check-in."], {}

    # Metrics
    moods = [c["mood_score"] for c in checkins]
    avg_mood = sum(moods) / n
    first_half = moods[: n // 2] if n > 1 else moods
    second_half = moods[n // 2:] if n > 1 else moods
    avg_first = sum(first_half) / len(first_half) if first_half else 0
    avg_second = sum(second_half) / len(second_half) if second_half else 0

    if avg_second > avg_first + 0.3:
        mood_trend = "up"
    elif avg_second < avg_first - 0.3:
        mood_trend = "down"
    else:
        mood_trend = "stable"

    neg_count = sum(1 for s in sentiments if s["sentiment"] == "negative")
    pos_count = sum(1 for s in sentiments if s["sentiment"] == "positive")
    stress = "high" if neg_count / n > 0.5 else ("medium" if neg_count / n > 0.25 else "low")
    positive_score = round(pos_count / n * 100)

    # Bullet 1: mood summary
    mood_label = "tích cực" if avg_mood >= 3.5 else ("trung bình" if avg_mood >= 2.5 else "thấp")
    bullets.append(f"Tâm trạng trung bình tuần này: {mood_label} ({avg_mood:.1f}/5).")

    # Bullet 2: trend
    trend_vi = {"up": "cải thiện", "down": "giảm", "stable": "ổn định"}
    bullets.append(f"Xu hướng cảm xúc: {trend_vi[mood_trend]}.")

    # Bullet 3: stress
    stress_vi = {"low": "thấp", "medium": "trung bình", "high": "cao"}
    bullets.append(f"Mức độ stress: {stress_vi[stress]}.")

    # Bullet 4: topics
    if topics:
        bullets.append(f"Chủ đề nổi bật: {', '.join(topics)}.")

    # Bullet 5: positive
    if positive_score > 50:
        bullets.append(f"Bạn có {positive_score}% ngày tích cực. Tiếp tục nhé!")
    elif positive_score > 0:
        bullets.append(f"Chỉ {positive_score}% ngày tích cực. Hãy chăm sóc bản thân hơn.")

    # Max 5 bullets, <=20 words each
    bullets = [b[:100] for b in bullets[:5]]

    metrics = {
        "avg_mood": round(avg_mood, 2),
        "mood_trend": mood_trend,
        "stress_level": stress,
        "top_topics": topics,
        "positive_score": positive_score,
    }

    return bullets, metrics
