# INNERLOG AI – REVIEW & IMPROVEMENT PLAN

> Reviewed: April 2026
> Scope: Full codebase review across 4 components + spec alignment
> Goals: UI/UX improvement, App Store rating boost, functionality gaps, AI performance

---

## EXECUTIVE SUMMARY

InnerLog AI has a solid foundation — clean architecture, good separation of concerns, and a well-thought-out spec. However, there are significant gaps between the spec (Level C: 70-80 functions) and the current implementation. The AI engine is mostly rule-based stubs, the mobile UX needs polish for retention, and several monetization-critical features are missing.

---

## 1. UI/UX IMPROVEMENTS (Mobile + Admin)

### 1.1 Mobile App — Critical UX Issues

| Issue | Impact | Priority |
|-------|--------|----------|
| No onboarding flow | Users drop off immediately — no context on what InnerLog does | P0 |
| No bottom sheet / home screen | After login, user lands on check-in only — no overview | P0 |
| NavigationBar duplicated in every screen | Should use ShellRoute with persistent nav | P1 |
| No animations or transitions | App feels static and lifeless | P1 |
| No empty states with illustrations | "Chưa có insight" is not engaging | P1 |
| No pull-to-refresh | Users can't refresh data manually | P1 |
| No loading skeletons | Just CircularProgressIndicator — feels slow | P2 |
| No haptic feedback on mood selection | Mood picker needs tactile response | P2 |
| Check-in screen not scrollable | Will overflow on smaller screens | P1 |
| No dark mode toggle in settings | Theme exists but no user control | P2 |

### 1.2 Mobile App — UX Improvements for Retention

| Improvement | Why It Matters |
|-------------|----------------|
| **Onboarding (3 screens)** | Explain value prop, set reminder, first check-in |
| **Home Dashboard screen** | Show streak, today's mood, quick insight summary, coach alerts |
| **Mood calendar/heatmap** | Visual motivation — API exists (`/checkins/heatmap`) but no UI |
| **Charts on Insight screen** | `fl_chart` is in pubspec but never used — add mood trend line chart |
| **Streak celebration animation** | Confetti/animation when streak milestone hit (7, 30, 100 days) |
| **Smart notification wording** | Current coach messages are generic — personalize with user name |
| **Micro-interaction on check-in** | Success animation after check-in, not just text message |
| **Tags UI on check-in** | Tags field exists in model but no UI to add/select tags |
| **Insight history list** | API exists but mobile only shows latest — add history screen |
| **Coach alerts screen** | Notifications API exists but no dedicated screen in mobile |

### 1.3 Admin UI — Issues

| Issue | Fix |
|-------|-----|
| No charts on dashboard | `ng2-charts` mentioned in docs but not implemented — add line charts for signups/checkins |
| No date range filter on check-ins | API supports `from`/`to` but UI doesn't use it |
| No insight generation trigger | Admin can't manually trigger insight for a user |
| No goal management view | Goals page exists but likely minimal |
| No notification management | Can't see/manage coach notifications |
| No admin role check | Dashboard accessible to any authenticated user — needs role guard |

---

## 2. APP STORE / CH PLAY RATING IMPROVEMENTS

### 2.1 Technical Requirements for High Rating

| Requirement | Current Status | Action |
|-------------|---------------|--------|
| Crash-free rate > 99.5% | No error boundary in Flutter | Add `FlutterError.onError` + `runZonedGuarded` |
| App startup < 2s | No splash screen optimization | Add native splash + lazy loading |
| Offline support | No offline capability | Add local SQLite cache for check-ins |
| Deep linking | Not configured | Add deep links for notifications |
| Accessibility | No semantic labels | Add `Semantics` widgets, proper contrast |
| Localization | Hardcoded Vietnamese | Add `intl` proper i18n (vi + en) |
| App size < 30MB | Unknown | Tree-shake, remove unused packages |

### 2.2 Store Listing Optimization (ASO)

| Element | Recommendation |
|---------|---------------|
| App name | "InnerLog – Nhật ký cảm xúc AI" (keyword-rich) |
| Short description | "Theo dõi tâm trạng, AI phân tích xu hướng, Silent Coach thông minh" |
| Screenshots | 5-6 screens: onboarding, check-in, insight, streak, goals, coach |
| Feature graphic | Gradient purple + emoji mood faces + "AI Personal Coach" |
| Category | Health & Fitness (primary), Lifestyle (secondary) |
| Privacy policy | Required — create privacy page explaining local AI, no data selling |

### 2.3 Rating Prompt Strategy

| Trigger | When |
|---------|------|
| After 7-day streak | User is engaged, likely to rate positively |
| After viewing positive insight | User feels good about progress |
| After completing a goal | Achievement moment |
| Never after negative coach alert | User is stressed — bad timing |

### 2.4 Features That Drive 5-Star Reviews

- **Streak gamification** — badges, milestones, share streak image
- **Weekly insight push notification** — "Your weekly insight is ready 📊"
- **Export as beautiful image** — shareable insight card (not just JSON)
- **Widget** — Home screen widget showing today's mood + streak
- **Quick check-in from notification** — 1-tap mood selection

---

## 3. FUNCTIONALITY GAPS (Spec vs Implementation)

### 3.1 Spec Level C Features — Missing Implementation

| Spec Feature | Status | Priority |
|-------------|--------|----------|
| **Forgot password (email send)** | Stub only — returns dev token | P1 |
| **Check-in reminder (push notification)** | Model has `reminder_enabled` but no scheduler | P0 |
| **Auto-adjust reminder by behavior** | Not implemented | P2 |
| **Long-term insight (30/60/90d)** | API supports period param but no UI trigger | P1 |
| **Insight comparison UI** | API exists (`/insights/compare`) but no UI | P2 |
| **Silent Coach push notification** | Alerts saved as DB notifications but no push | P0 |
| **Goal breakdown (AI-suggested tasks)** | Manual only — no AI task suggestion | P2 |
| **Procrastination detection** | Not implemented | P2 |
| **PDF report generation** | Not implemented at all | P1 |
| **Share link (read-only insight)** | Not implemented | P2 |
| **Subscription/payment integration** | Plan field exists but no payment flow | P1 |
| **One-time packages** | Not implemented | P2 |
| **Feature flags** | Not implemented | P2 |
| **Usage analytics** | Not implemented | P1 |
| **Error monitoring** | No Sentry/equivalent | P1 |
| **Abuse protection** | Basic rate limit only | P2 |
| **Dark/Light mode toggle** | Theme exists, no toggle UI | P1 |
| **Notification settings (per-type)** | Not implemented | P2 |
| **Silent hours** | Not implemented | P2 |

### 3.2 Backend Gaps

| Gap | Detail |
|-----|--------|
| No input validation middleware | Routes trust req.body blindly — need Joi/Zod |
| No pagination on checkins | Returns all check-ins — will be slow at scale |
| No admin role enforcement | Any user can access `/dashboard` |
| No email service | Forgot password, weekly digest, etc. |
| No scheduled jobs | Weekly insight auto-generation, reminder push |
| No WebSocket | Real-time notifications not possible |
| No API versioning middleware | Just path prefix, no version negotiation |
| User.select('+password_hash') issue | `password_hash` not excluded by default in schema `select` |

### 3.3 Mobile Gaps

| Gap | Detail |
|-----|--------|
| No state management | Riverpod in pubspec but not used — all local state |
| No token refresh logic | Token expires in 15m, no auto-refresh in Dio interceptor |
| No error handling patterns | Generic catch blocks everywhere |
| No form validation | Can submit empty email/password |
| ApiClient created per-screen | Should be singleton via Riverpod provider |
| No image picker for avatar | Profile shows avatar field but no upload |

---

## 4. AI ENGINE IMPROVEMENTS (Free Python Stack)

### 4.1 Current State Assessment

| Component | Current | Issue |
|-----------|---------|-------|
| Sentiment | `mood_score` threshold only | Ignores `text_note` entirely — not real NLP |
| Clustering | Keyword matching (hardcoded lists) | No embedding, no learning, misses context |
| Insight Generator | Rule-based string templates | No LLM integration despite spec mentioning Ollama |
| Pattern Detector | Simple threshold rules | No time-series analysis, no trend prediction |
| Trend Compare | Basic average diff | No statistical significance, no visualization data |

### 4.2 Improvement Plan — All Free/Open-Source

#### Phase 1: Real Sentiment Analysis (sentence-transformers — already in requirements.txt)

```python
# BEFORE (current): Just mood_score threshold
def analyze_sentiment(checkins):
    for c in checkins:
        mood = c.get("mood_score", 3)
        if mood >= 4: sentiment = "positive"  # Ignores text completely!

# AFTER: Use sentence-transformers for text analysis
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')  # FREE, supports Vietnamese

SENTIMENT_ANCHORS = {
    "positive": ["vui vẻ", "hạnh phúc", "tuyệt vời", "năng lượng", "tốt đẹp"],
    "negative": ["buồn", "stress", "mệt mỏi", "lo lắng", "chán nản", "áp lực"],
    "neutral": ["bình thường", "ổn", "không có gì đặc biệt"],
}

# Pre-compute anchor embeddings (once at startup)
anchor_embeddings = {k: model.encode(v) for k, v in SENTIMENT_ANCHORS.items()}

def analyze_sentiment_v2(checkins):
    results = []
    for c in checkins:
        text = c.get("text_note", "")
        mood = c.get("mood_score", 3)

        if text and len(text.strip()) > 3:
            # Text-based sentiment (weighted 60%)
            text_emb = model.encode([text])[0]
            scores = {}
            for label, anchors in anchor_embeddings.items():
                sims = cosine_similarity([text_emb], anchors)[0]
                scores[label] = float(np.max(sims))
            text_sentiment = max(scores, key=scores.get)
            text_confidence = scores[text_sentiment]

            # Mood-based sentiment (weighted 40%)
            mood_sentiment = "positive" if mood >= 4 else ("negative" if mood <= 2 else "neutral")

            # Combine: text wins if confident, else mood wins
            if text_confidence > 0.5:
                final_sentiment = text_sentiment
            else:
                final_sentiment = mood_sentiment
        else:
            # No text — fall back to mood only
            final_sentiment = "positive" if mood >= 4 else ("negative" if mood <= 2 else "neutral")

        results.append({
            "created_at": c.get("created_at"),
            "sentiment": final_sentiment,
            "score": mood / 5.0,
            "text_note": text,
        })
    return results
```

#### Phase 2: Embedding-Based Topic Clustering (scikit-learn — already in requirements.txt)

```python
# BEFORE: Hardcoded keyword matching
# AFTER: Semantic clustering with embeddings

from sentence_transformers import SentenceTransformer
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
from collections import Counter
import numpy as np

model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

# Topic label mapping via closest anchor
TOPIC_ANCHORS = {
    "work": "công việc, deadline, meeting, dự án, sếp",
    "study": "học tập, thi cử, bài vở, trường lớp",
    "health": "sức khỏe, tập thể dục, ngủ, mệt mỏi",
    "relationship": "bạn bè, gia đình, người yêu, cô đơn",
    "finance": "tiền bạc, chi tiêu, lương, mua sắm",
    "mood": "cảm xúc, vui buồn, lo lắng, stress",
}
topic_anchor_embs = {k: model.encode([v])[0] for k, v in TOPIC_ANCHORS.items()}

def cluster_topics_v2(checkins):
    texts = [c.get("text_note", "") for c in checkins if c.get("text_note", "").strip()]
    if len(texts) < 3:
        # Fall back to keyword matching for small datasets
        return cluster_topics_keyword(checkins)

    embeddings = model.encode(texts)

    # Auto-determine k (2-5 clusters)
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

    # Label each cluster by closest topic anchor
    topics = []
    for center in km.cluster_centers_:
        best_topic, best_sim = "other", -1
        for topic, anchor_emb in topic_anchor_embs.items():
            sim = float(np.dot(center, anchor_emb) / (np.linalg.norm(center) * np.linalg.norm(anchor_emb)))
            if sim > best_sim:
                best_topic, best_sim = topic, sim
        topics.append(best_topic)

    # Return top 3 by frequency
    topic_counts = Counter(topics[l] for l in labels)
    return [t for t, _ in topic_counts.most_common(3)]
```

#### Phase 3: LLM-Powered Insight Generation (Ollama — FREE, local)

```python
# BEFORE: Hardcoded Vietnamese string templates
# AFTER: Ollama LLM generates natural, personalized insights

import httpx
import json

OLLAMA_URL = "http://localhost:11434"
OLLAMA_MODEL = "llama3.1:8b"  # or "mistral:7b" — both FREE

async def generate_insight_llm(checkins, sentiments, topics, metrics):
    """Generate natural language insight bullets using local Ollama LLM."""

    # Build context summary for LLM
    context = f"""Dữ liệu check-in {len(checkins)} ngày:
- Mood trung bình: {metrics['avg_mood']}/5
- Xu hướng: {metrics['mood_trend']}
- Stress: {metrics['stress_level']}
- Chủ đề chính: {', '.join(topics) if topics else 'không rõ'}
- Tỷ lệ ngày tích cực: {metrics['positive_score']}%
- Ghi chú gần nhất: {'; '.join(c.get('text_note','') for c in checkins[-3:] if c.get('text_note'))}"""

    prompt = f"""Bạn là AI coach cá nhân. Dựa trên dữ liệu check-in dưới đây, tạo ĐÚNG 5 bullet insight ngắn gọn (mỗi bullet ≤20 từ) bằng tiếng Việt.

{context}

Quy tắc:
- Mỗi bullet bắt đầu bằng emoji phù hợp
- Giọng văn ấm áp, khích lệ nhưng thực tế
- Bullet cuối luôn là lời khuyên hành động cụ thể
- Trả về JSON array: ["bullet1", "bullet2", ...]
- KHÔNG giải thích thêm, CHỈ trả JSON array"""

    try:
        async with httpx.AsyncClient(timeout=30) as client:
            resp = await client.post(f"{OLLAMA_URL}/api/generate", json={
                "model": OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False,
                "options": {"temperature": 0.7, "num_predict": 300}
            })
            text = resp.json().get("response", "")
            # Parse JSON from LLM response
            bullets = json.loads(text.strip())
            if isinstance(bullets, list) and len(bullets) >= 3:
                return bullets[:5]
    except Exception:
        pass

    # Fallback to rule-based if LLM fails
    return generate_insight_rules(checkins, sentiments, topics, metrics)
```

#### Phase 4: Time-Series Pattern Detection (numpy + scipy — FREE)

```python
# BEFORE: Simple consecutive count thresholds
# AFTER: Statistical trend detection + moving averages

import numpy as np
from scipy import stats

def detect_patterns_v2(checkins):
    alerts = []
    if len(checkins) < 5:
        return alerts

    moods = np.array([c["mood_score"] for c in checkins])
    e_map = {"low": 1, "normal": 2, "high": 3}
    energies = np.array([e_map.get(c["energy_level"], 2) for c in checkins])

    # 1. Statistical mood trend (linear regression)
    x = np.arange(len(moods))
    slope, _, r_value, p_value, _ = stats.linregress(x, moods)
    if slope < -0.15 and p_value < 0.1:
        alerts.append({
            "type": "mood_declining",
            "message": f"Tâm trạng có xu hướng giảm dần ({slope:.2f}/ngày). Hãy chú ý chăm sóc bản thân.",
            "severity": "warning",
            "confidence": round(abs(r_value), 2),
        })

    # 2. Volatility detection (mood swings)
    if len(moods) >= 7:
        rolling_std = np.std(moods[-7:])
        if rolling_std > 1.2:
            alerts.append({
                "type": "mood_volatile",
                "message": "Cảm xúc dao động nhiều trong tuần qua. Thử duy trì routine ổn định.",
                "severity": "info",
            })

    # 3. Moving average crossover (short-term vs long-term)
    if len(moods) >= 10:
        ma_short = np.convolve(moods, np.ones(3)/3, mode='valid')
        ma_long = np.convolve(moods, np.ones(7)/7, mode='valid')
        min_len = min(len(ma_short), len(ma_long))
        if min_len >= 2:
            if ma_short[-1] < ma_long[-1] and ma_short[-2] >= ma_long[-2]:
                alerts.append({
                    "type": "downtrend_signal",
                    "message": "Tâm trạng ngắn hạn đang thấp hơn trung bình. Đây có thể là giai đoạn khó khăn.",
                    "severity": "warning",
                })

    # 4. Energy-mood correlation
    if len(moods) >= 7:
        corr, _ = stats.pearsonr(moods[-7:], energies[-7:])
        if corr > 0.7:
            alerts.append({
                "type": "energy_mood_linked",
                "message": "Năng lượng và tâm trạng liên quan chặt chẽ. Cải thiện giấc ngủ có thể giúp mood tốt hơn.",
                "severity": "info",
            })

    # 5. Weekend vs weekday pattern
    # (keep existing patterns too: stress_spike, burnout_risk, missed_checkins)

    return alerts
```

#### Phase 5: Performance Optimization

```python
# Key optimizations for the AI engine:

# 1. Model lazy loading + singleton
_model = None
def get_model():
    global _model
    if _model is None:
        _model = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')
    return _model

# 2. Batch encoding (not one-by-one)
texts = [c["text_note"] for c in checkins if c.get("text_note")]
embeddings = get_model().encode(texts, batch_size=32, show_progress_bar=False)

# 3. Cache embeddings in Redis (avoid re-computing)
# Key: sha256(text) → embedding vector
# TTL: 24h (text doesn't change)

# 4. Async Ollama calls with timeout + fallback
# If Ollama takes > 10s → fall back to rule-based

# 5. Add /ai/health endpoint with model load status
@app.get("/ai/health")
def health():
    return {
        "status": "ok",
        "model_loaded": _model is not None,
        "ollama_available": check_ollama(),
    }
```

### 4.3 Updated requirements.txt (All FREE)

```
fastapi==0.115.0
uvicorn==0.30.0
pydantic==2.9.0
numpy==1.26.4
pandas==2.2.0
scikit-learn==1.5.0
sentence-transformers==3.0.0
httpx==0.27.0
python-dotenv==1.0.1
scipy==1.14.0          # NEW: statistical analysis
torch==2.4.0           # Required by sentence-transformers (CPU only)
# Removed: transformers (sentence-transformers includes it)
```

### 4.4 AI Performance Benchmarks (Expected)

| Metric | Before (Rule-based) | After (ML + LLM) |
|--------|--------------------|--------------------|
| Sentiment accuracy | ~60% (mood-only) | ~85% (text + mood) |
| Topic relevance | ~50% (keyword match) | ~80% (embedding cluster) |
| Insight quality | Generic templates | Personalized, natural language |
| Pattern detection | 5 simple rules | 8+ statistical patterns |
| Response time | <100ms | ~500ms (ML) / ~3s (LLM with fallback) |
| Cold start | Instant | ~5s (model load, then cached) |

---

## 5. IMPLEMENTATION PRIORITY ROADMAP

### Sprint 1 (Week 1-2): Foundation & Quick Wins
1. ✅ Add input validation (Zod) to all backend routes
2. ✅ Fix NavigationBar duplication → ShellRoute
3. ✅ Add token auto-refresh in Dio interceptor
4. ✅ Add onboarding flow (3 screens)
5. ✅ Add Home Dashboard screen
6. ✅ Implement real sentiment analysis (sentence-transformers)
7. ✅ Add error boundaries in Flutter

### Sprint 2 (Week 3-4): AI & Core Features
1. ✅ Implement embedding-based clustering
2. ✅ Integrate Ollama for insight generation
3. ✅ Add statistical pattern detection
4. ✅ Add mood heatmap UI (calendar view)
5. ✅ Add charts to Insight screen (fl_chart)
6. ✅ Implement push notifications (Firebase)
7. ✅ Add check-in reminder scheduler

### Sprint 3 (Week 5-6): Monetization & Polish
1. ✅ Payment integration (RevenueCat — handles both stores)
2. ✅ Feature gating (free vs premium)
3. ✅ PDF report generation
4. ✅ Admin dashboard charts
5. ✅ Admin role enforcement
6. ✅ In-app rating prompt (after 7-day streak)
7. ✅ App Store / CH Play listing optimization

### Sprint 4 (Week 7-8): Scale & Quality
1. ✅ Offline check-in support (SQLite)
2. ✅ Error monitoring (Sentry)
3. ✅ Usage analytics (Mixpanel free tier)
4. ✅ Localization (vi + en)
5. ✅ Accessibility audit
6. ✅ Performance optimization
7. ✅ Beta testing + feedback loop

---

## 6. COST ANALYSIS (All Free/Low-Cost)

| Component | Cost |
|-----------|------|
| AI Models (sentence-transformers, Ollama) | FREE (self-hosted) |
| scikit-learn, scipy, numpy | FREE (open-source) |
| Flutter + Dart | FREE |
| Angular + ArchitectUI Free | FREE |
| MongoDB Community | FREE |
| Redis | FREE |
| VPS (deployment) | ~$24/month |
| Cloudflare Tunnel | FREE |
| Firebase (push notifications) | FREE tier |
| RevenueCat (payments) | FREE until $2.5k MRR |
| Sentry (error monitoring) | FREE tier (5k events/mo) |
| **Total** | **~$24/month** |

---

END OF REVIEW
