from typing import List


def analyze_sentiment(checkins: List[dict]) -> List[dict]:
    """
    Analyze sentiment from check-in data.
    Uses mood_score + text_note for sentiment classification.
    Future: integrate sentence-transformers for text embedding.
    """
    results = []
    for c in checkins:
        mood = c.get("mood_score", 3)
        if mood >= 4:
            sentiment = "positive"
        elif mood <= 2:
            sentiment = "negative"
        else:
            sentiment = "neutral"

        results.append({
            "created_at": c.get("created_at"),
            "sentiment": sentiment,
            "score": mood / 5.0,
            "text_note": c.get("text_note", ""),
        })
    return results
