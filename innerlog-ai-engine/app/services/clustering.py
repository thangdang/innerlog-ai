from typing import List
import re
from collections import Counter


# Vietnamese keyword categories
TOPIC_KEYWORDS = {
    "work": ["công việc", "work", "deadline", "meeting", "sếp", "đồng nghiệp", "dự án", "project"],
    "study": ["học", "thi", "bài", "study", "exam", "trường", "lớp", "điểm"],
    "health": ["sức khỏe", "mệt", "ngủ", "tập", "gym", "ốm", "đau", "health", "sleep", "tired"],
    "relationship": ["bạn", "người yêu", "gia đình", "family", "friend", "cô đơn", "lonely"],
    "finance": ["tiền", "lương", "chi tiêu", "money", "salary", "mua", "trả"],
    "mood": ["vui", "buồn", "lo", "stress", "happy", "sad", "anxious", "tức", "angry"],
}


def cluster_topics(checkins: List[dict]) -> List[str]:
    """
    Simple keyword-based topic clustering from text notes.
    Future: use sentence-transformers + KMeans for embedding-based clustering.
    """
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

    # Return top 3 topics
    return [t for t, _ in topic_counts.most_common(3)]
