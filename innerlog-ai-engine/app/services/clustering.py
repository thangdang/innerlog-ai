"""
Topic clustering — hybrid approach:
  1. If enough text notes + embedding model available → KMeans on embeddings
  2. Fallback → keyword-based matching (Vietnamese + English)
"""
from typing import List
from collections import Counter
import logging
import numpy as np

from app.services.model_loader import get_embedding_model

logger = logging.getLogger(__name__)

# ── Keyword fallback ──────────────────────────────────────────────
TOPIC_KEYWORDS = {
    "work": [
        "công việc", "work", "deadline", "meeting", "sếp",
        "đồng nghiệp", "dự án", "project", "overtime", "tăng ca",
    ],
    "study": [
        "học", "thi", "bài", "study", "exam", "trường",
        "lớp", "điểm", "luận văn", "assignment",
    ],
    "health": [
        "sức khỏe", "mệt", "ngủ", "tập", "gym", "ốm",
        "đau", "health", "sleep", "tired", "bệnh",
    ],
    "relationship": [
        "bạn", "người yêu", "gia đình", "family", "friend",
        "cô đơn", "lonely", "crush", "chia tay",
    ],
    "finance": [
        "tiền", "lương", "chi tiêu", "money", "salary",
        "mua", "trả", "nợ", "tiết kiệm",
    ],
    "mood": [
        "vui", "buồn", "lo", "stress", "happy", "sad",
        "anxious", "tức", "angry", "khóc",
    ],
}

# ── Embedding-based topic anchors ─────────────────────────────────
TOPIC_ANCHOR_TEXTS = {
    "work": "công việc, deadline, meeting, dự án, sếp, đồng nghiệp",
    "study": "học tập, thi cử, bài vở, trường lớp, điểm số",
    "health": "sức khỏe, tập thể dục, ngủ, mệt mỏi, bệnh",
    "relationship": "bạn bè, gia đình, người yêu, cô đơn, tình cảm",
    "finance": "tiền bạc, chi tiêu, lương, mua sắm, tiết kiệm",
    "mood": "cảm xúc, vui buồn, lo lắng, stress, tâm trạng",
}

_topic_anchor_cache = None


def _get_topic_anchors():
    global _topic_anchor_cache
    if _topic_anchor_cache is not None:
        return _topic_anchor_cache
    model = get_embedding_model()
    if model is None:
        return None
    _topic_anchor_cache = {
        k: model.encode([v], show_progress_bar=False)[0]
        for k, v in TOPIC_ANCHOR_TEXTS.items()
    }
    return _topic_anchor_cache


def _cluster_keyword(checkins: List[dict]) -> List[str]:
    """Keyword-based fallback clustering."""
    topic_counts: Counter = Counter()
    for c in checkins:
        text = (c.get("text_note") or "").lower()
        if not text:
            continue
        for topic, keywords in TOPIC_KEYWORDS.items():
            for kw in keywords:
                if kw in text:
                    topic_counts[topic] += 1
                    break
    return [t for t, _ in topic_counts.most_common(3)]


def _cluster_embedding(texts: List[str]) -> List[str]:
    """Embedding + KMeans clustering with topic anchor labeling."""
    from sklearn.cluster import KMeans
    from sklearn.metrics import silhouette_score

    model = get_embedding_model()
    anchors = _get_topic_anchors()
    if model is None or anchors is None:
        return []

    embeddings = model.encode(texts, batch_size=32, show_progress_bar=False)

    # Auto-determine k (2–5)
    best_k, best_score = 2, -1
    for k in range(2, min(6, len(texts))):
        km = KMeans(n_clusters=k, random_state=42, n_init=10)
        labels = km.fit_predict(embeddings)
        if len(set(labels)) > 1:
            score = silhouette_score(embeddings, labels)
            if score > best_score:
                best_k, best_score = k, score

    km = KMeans(n_clusters=best_k, random_state=42, n_init=10)
    labels = km.fit_predict(embeddings)

    # Label each cluster center by closest topic anchor
    cluster_topics = []
    for center in km.cluster_centers_:
        best_topic, best_sim = "other", -1.0
        c_norm = np.linalg.norm(center)
        for topic, anchor_emb in anchors.items():
            sim = float(np.dot(center, anchor_emb) / (c_norm * np.linalg.norm(anchor_emb) + 1e-9))
            if sim > best_sim:
                best_topic, best_sim = topic, sim
        cluster_topics.append(best_topic)

    # Count by frequency
    topic_counts = Counter(cluster_topics[l] for l in labels)
    return [t for t, _ in topic_counts.most_common(3)]


def cluster_topics(checkins: List[dict]) -> List[str]:
    """
    Cluster check-in text notes into topics.
    Uses embedding-based KMeans when possible, keyword fallback otherwise.
    """
    texts = [
        c.get("text_note", "").strip()
        for c in checkins
        if (c.get("text_note") or "").strip()
    ]

    # Need at least 4 texts for meaningful clustering
    if len(texts) >= 4 and get_embedding_model() is not None:
        try:
            result = _cluster_embedding(texts)
            if result:
                return result
        except Exception as exc:
            logger.warning("Embedding clustering failed, falling back: %s", exc)

    return _cluster_keyword(checkins)
