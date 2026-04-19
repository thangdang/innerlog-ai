"""
Insight generator — hybrid approach:
  1. Primary: Ollama LLM (local, free) for natural Vietnamese bullets
  2. Fallback: rule-based templates when Ollama is offline
  Max 5 bullets, ≤20 words each.
"""
import json
import logging
import os
from typing import List, Tuple

import httpx

logger = logging.getLogger(__name__)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "llama3.1:8b")
OLLAMA_TIMEOUT = 15


def _compute_metrics(
    checkins: List[dict], sentiments: List[dict], topics: List[str]
) -> dict:
    """Compute insight metrics from checkin data (always rule-based)."""
    n = len(checkins)
    if n == 0:
        return {
            "avg_mood": 0, "mood_trend": "unknown",
            "stress_level": "unknown", "top_topics": [], "positive_score": 0,
        }

    moods = [c["mood_score"] for c in checkins]
    avg_mood = sum(moods) / n

    first_half = moods[: n // 2] if n > 1 else moods
    second_half = moods[n // 2 :] if n > 1 else moods
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
    stress = (
        "high" if neg_count / n > 0.5
        else ("medium" if neg_count / n > 0.25 else "low")
    )
    positive_score = round(pos_count / n * 100)

    return {
        "avg_mood": round(avg_mood, 2),
        "mood_trend": mood_trend,
        "stress_level": stress,
        "top_topics": topics,
        "positive_score": positive_score,
    }


def _generate_rule_bullets(
    checkins: List[dict], metrics: dict, topics: List[str]
) -> List[str]:
    """Rule-based bullet generation (fallback)."""
    bullets = []
    avg_mood = metrics["avg_mood"]
    mood_trend = metrics["mood_trend"]
    stress = metrics["stress_level"]
    positive_score = metrics["positive_score"]

    mood_label = (
        "tích cực" if avg_mood >= 3.5
        else ("trung bình" if avg_mood >= 2.5 else "thấp")
    )
    bullets.append(
        f"😊 Tâm trạng trung bình tuần này: {mood_label} ({avg_mood:.1f}/5)."
    )

    trend_vi = {"up": "cải thiện ↑", "down": "giảm ↓", "stable": "ổn định →"}
    bullets.append(f"📈 Xu hướng cảm xúc: {trend_vi.get(mood_trend, 'chưa rõ')}.")

    stress_vi = {"low": "thấp ✅", "medium": "trung bình ⚠️", "high": "cao 🔴"}
    bullets.append(f"🧠 Mức độ stress: {stress_vi.get(stress, 'chưa rõ')}.")

    if topics:
        bullets.append(f"💬 Chủ đề nổi bật: {', '.join(topics)}.")

    if positive_score > 50:
        bullets.append(
            f"🌟 Bạn có {positive_score}% ngày tích cực. Tiếp tục nhé!"
        )
    elif positive_score > 0:
        bullets.append(
            f"💪 Chỉ {positive_score}% ngày tích cực. Hãy chăm sóc bản thân hơn."
        )
    else:
        bullets.append("🌱 Hãy thử ghi chú cảm xúc mỗi ngày để AI hiểu bạn hơn.")

    return [b[:100] for b in bullets[:5]]


async def _generate_llm_bullets(
    checkins: List[dict], metrics: dict, topics: List[str]
) -> List[str] | None:
    """Generate insight bullets via local Ollama LLM. Returns None on failure."""
    recent_notes = "; ".join(
        c.get("text_note", "") for c in checkins[-5:] if c.get("text_note")
    )

    context = (
        f"Dữ liệu check-in {len(checkins)} ngày:\n"
        f"- Mood trung bình: {metrics['avg_mood']}/5\n"
        f"- Xu hướng: {metrics['mood_trend']}\n"
        f"- Stress: {metrics['stress_level']}\n"
        f"- Chủ đề chính: {', '.join(topics) if topics else 'không rõ'}\n"
        f"- Tỷ lệ ngày tích cực: {metrics['positive_score']}%\n"
        f"- Ghi chú gần nhất: {recent_notes or 'không có'}"
    )

    prompt = (
        "Bạn là AI coach cá nhân. Dựa trên dữ liệu check-in dưới đây, "
        "tạo ĐÚNG 5 bullet insight ngắn gọn (mỗi bullet ≤20 từ) bằng tiếng Việt.\n\n"
        f"{context}\n\n"
        "Quy tắc:\n"
        "- Mỗi bullet bắt đầu bằng emoji phù hợp\n"
        "- Giọng văn ấm áp, khích lệ nhưng thực tế\n"
        "- Bullet cuối luôn là lời khuyên hành động cụ thể\n"
        '- Trả về JSON array: ["bullet1", "bullet2", ...]\n'
        "- KHÔNG giải thích thêm, CHỈ trả JSON array"
    )

    try:
        async with httpx.AsyncClient(timeout=OLLAMA_TIMEOUT) as client:
            resp = await client.post(
                f"{OLLAMA_URL}/api/generate",
                json={
                    "model": OLLAMA_MODEL,
                    "prompt": prompt,
                    "stream": False,
                    "options": {"temperature": 0.7, "num_predict": 400},
                },
            )
            resp.raise_for_status()
            text = resp.json().get("response", "").strip()

            # Try to extract JSON array from response
            # LLM might wrap it in markdown code block
            if "```" in text:
                text = text.split("```")[1]
                if text.startswith("json"):
                    text = text[4:]
                text = text.strip()

            bullets = json.loads(text)
            if isinstance(bullets, list) and 3 <= len(bullets) <= 7:
                # Truncate to 5, ensure strings
                return [str(b)[:100] for b in bullets[:5]]

            logger.warning("Ollama returned invalid format: %s", type(bullets))
            return None

    except httpx.ConnectError:
        logger.debug("Ollama not available at %s", OLLAMA_URL)
        return None
    except Exception as exc:
        logger.warning("Ollama insight generation failed: %s", exc)
        return None


async def generate_insight_bullets(
    checkins: List[dict],
    sentiments: List[dict],
    topics: List[str],
) -> Tuple[List[str], dict]:
    """
    Generate insight bullets (max 5, ≤20 words each).
    Tries Ollama LLM first, falls back to rule-based.
    """
    if not checkins:
        return ["Chưa có dữ liệu check-in."], {}

    metrics = _compute_metrics(checkins, sentiments, topics)

    # Try LLM first
    llm_bullets = await _generate_llm_bullets(checkins, metrics, topics)
    if llm_bullets:
        logger.info("Insight generated via Ollama LLM (%d bullets)", len(llm_bullets))
        return llm_bullets, metrics

    # Fallback to rule-based
    logger.info("Insight generated via rule-based fallback")
    rule_bullets = _generate_rule_bullets(checkins, metrics, topics)
    return rule_bullets, metrics
