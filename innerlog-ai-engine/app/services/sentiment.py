"""
Sentiment analysis — hybrid approach:
  1. If text_note exists and embedding model is available → text-based NLP (60% weight)
  2. Always uses mood_score as baseline (40% weight / 100% fallback)
Uses paraphrase-multilingual-MiniLM-L12-v2 (FREE, supports Vietnamese).
"""
from typing import List, Optional
import logging
import numpy as np

from app.services.model_loader import get_embedding_model

logger = logging.getLogger(__name__)

# Anchor phrases for cosine-similarity sentiment classification
SENTIMENT_ANCHORS = {
    "positive": [
        "vui vẻ", "hạnh phúc", "tuyệt vời", "năng lượng tốt", "tốt đẹp",
        "phấn khởi", "hào hứng", "thoải mái", "biết ơn", "yêu đời",
    ],
    "negative": [
        "buồn", "stress", "mệt mỏi", "lo lắng", "chán nản", "áp lực",
        "tức giận", "thất vọng", "cô đơn", "kiệt sức", "sợ hãi",
    ],
    "neutral": [
        "bình thường", "ổn", "không có gì đặc biệt", "tạm được",
        "bình bình", "cũng được",
    ],
}

# Pre-computed anchor embeddings (populated on first call)
_anchor_cache: Optional[dict] = None


def _get_anchor_embeddings() -> Optional[dict]:
    """Encode anchor phrases once, cache in memory."""
    global _anchor_cache
    if _anchor_cache is not None:
        return _anchor_cache

    model = get_embedding_model()
    if model is None:
        return None

    _anchor_cache = {}
    for label, phrases in SENTIMENT_ANCHORS.items():
        _anchor_cache[label] = model.encode(phrases, batch_size=32, show_progress_bar=False)
    return _anchor_cache


def _text_sentiment(text: str) -> tuple:
    """Classify text sentiment via cosine similarity to anchors.
    Returns (label, confidence) or (None, 0) if model unavailable.
    """
    model = get_embedding_model()
    anchors = _get_anchor_embeddings()
    if model is None or anchors is None:
        return None, 0.0

    text_emb = model.encode([text], show_progress_bar=False)[0]
    scores = {}
    for label, anchor_embs in anchors.items():
        # cosine similarity against each anchor phrase, take max
        dots = np.dot(anchor_embs, text_emb)
        norms = np.linalg.norm(anchor_embs, axis=1) * np.linalg.norm(text_emb)
        sims = dots / (norms + 1e-9)
        scores[label] = float(np.max(sims))

    best_label = max(scores, key=scores.get)
    return best_label, scores[best_label]


def _mood_sentiment(mood: int) -> str:
    if mood >= 4:
        return "positive"
    elif mood <= 2:
        return "negative"
    return "neutral"


def analyze_sentiment(checkins: List[dict]) -> List[dict]:
    """
    Analyze sentiment from check-in data.
    Hybrid: text NLP (if available) + mood_score baseline.
    """
    # Batch-encode all texts that have content
    texts_with_idx = []
    for i, c in enumerate(checkins):
        text = (c.get("text_note") or "").strip()
        if text and len(text) > 3:
            texts_with_idx.append((i, text))

    # Batch encode for performance
    text_sentiments: dict = {}
    if texts_with_idx:
        model = get_embedding_model()
        anchors = _get_anchor_embeddings()
        if model is not None and anchors is not None:
            all_texts = [t for _, t in texts_with_idx]
            all_embs = model.encode(all_texts, batch_size=32, show_progress_bar=False)
            for (idx, _text), emb in zip(texts_with_idx, all_embs):
                scores = {}
                for label, anchor_embs in anchors.items():
                    dots = np.dot(anchor_embs, emb)
                    norms = np.linalg.norm(anchor_embs, axis=1) * np.linalg.norm(emb)
                    sims = dots / (norms + 1e-9)
                    scores[label] = float(np.max(sims))
                best = max(scores, key=scores.get)
                text_sentiments[idx] = (best, scores[best])

    results = []
    for i, c in enumerate(checkins):
        mood = c.get("mood_score", 3)
        mood_sent = _mood_sentiment(mood)

        if i in text_sentiments:
            text_label, confidence = text_sentiments[i]
            # Text wins if confident (>0.45), else mood wins
            final = text_label if confidence > 0.45 else mood_sent
        else:
            final = mood_sent

        results.append({
            "created_at": c.get("created_at"),
            "sentiment": final,
            "score": mood / 5.0,
            "text_note": c.get("text_note", ""),
        })

    return results
