# InnerLog AI — Hybrid Network Diagram

## 1. Tổng quan

Hybrid deployment với cache + fallback:
- **AI engine** (sentiment + clustering + Ollama insight + pattern detection) chạy trên Local PC
- **Backend + UI + DB** chạy trên VPS $24
- **Redis cache**: insight (6h), coach (1h) — tránh gọi AI lặp lại
- **Fallback**: PC offline → local JS fallback (basic mood analysis + pattern detection)
- **GDPR**: AI chạy trên PC cá nhân → dữ liệu sức khỏe tinh thần không gửi qua cloud LLM

## 2. Network Diagram

```
                    ┌──────────────────────────────────────┐
                    │           INTERNET                    │
                    └──────────┬───────────────────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
     ┌────────────┐   ┌──────────────┐   ┌──────────────┐
     │ Mobile App │   │ Admin UI     │   │ (No cloud    │
     │ (Flutter)  │   │ (Browser)    │   │  fallback    │
     │ Android/iOS│   │ admin.innerlog│  │  needed)     │
     └─────┬──────┘   └──────┬───────┘   └──────────────┘
           │                  │
           └──────────┬───────┘
                      │
    ══════════════════╪════════════════════════════════════
    VPS ($24/mo)      │  2 vCPU, 4GB RAM
    ══════════════════╪════════════════════════════════════
                      │
                      ▼
               ┌────────────┐
               │   Nginx    │
               │  SSL proxy │
               └─────┬──────┘
                     │
    ┌────────────────▼───────────────────────────────────┐
    │         innerlog-service (Express.js :3000)         │
    │                                                     │
    │  ┌───────────────────────────────────────────────┐  │
    │  │  /insights/generate                           │  │
    │  │    Try: AI engine /ai/analyze (15s timeout)   │  │
    │  │    Fallback: local JS (avg mood + basic trend)│  │
    │  ├───────────────────────────────────────────────┤  │
    │  │  /coach/check                                 │  │
    │  │    Try: AI engine /ai/coach (15s timeout)     │  │
    │  │    Fallback: local JS (mood drop + stress)    │  │
    │  ├───────────────────────────────────────────────┤  │
    │  │  /checkins/*     ✅ Always works (MongoDB)    │  │
    │  │  /goals/*        ✅ Always works (MongoDB)    │  │
    │  │  /auth/*         ✅ Always works (JWT)        │  │
    │  │  /notifications/* ✅ Always works (MongoDB)   │  │
    │  └───────────────────────────────────────────────┘  │
    └──────┬──────────┬──────────────────────────────────┘
           │          │              │
     ┌─────▼──┐  ┌────▼───┐  ┌──────▼─────┐
     │MongoDB │  │ Redis  │  │innerlog-ui │
     │ :27017 │  │ :6379  │  │ Nginx :80  │
     └────────┘  └────────┘  └────────────┘
                      │
    ══════════════════╪════════════════════════════════════
                      │ Cloudflare Tunnel (HTTPS)
    ══════════════════╪════════════════════════════════════
    LOCAL PC (Win 11) │  16GB RAM
    ══════════════════╪════════════════════════════════════
                      │
           ┌──────────▼──────────────────────────────────┐
           │        cloudflared tunnel                    │
           │  https://xxx.trycloudflare.com → :5000      │
           └──────────┬──────────────────────────────────┘
                      │
           ┌──────────▼──────────────────────────────────┐
           │   innerlog-ai-engine (FastAPI :5000)         │
           │                                              │
           │  ┌────────────────────────────────────────┐  │
           │  │ /ai/analyze                            │  │
           │  │   1. Sentiment (sentence-transformers) │  │
           │  │   2. Topic clustering (scikit-learn)   │  │
           │  │   3. Insight bullets (rule-based)      │  │
           │  │   Future: Ollama LLM summary           │  │
           │  ├────────────────────────────────────────┤  │
           │  │ /ai/coach                              │  │
           │  │   Pattern detection (5 detectors):     │  │
           │  │   - mood_drop (3+ consecutive days)    │  │
           │  │   - stress_spike (mood ≤ 2)            │  │
           │  │   - low_energy (3+ days)               │  │
           │  │   - missed_checkins (gap ≥ 3 days)     │  │
           │  │   - burnout_risk (low mood + energy)   │  │
           │  ├────────────────────────────────────────┤  │
           │  │ /ai/trend-compare                      │  │
           │  │   Period comparison                    │  │
           │  └────────────────────────────────────────┘  │
           │                                              │
           │  ┌──────────────┐  ┌──────────────────────┐  │
           │  │ sentence-    │  │ scikit-learn          │  │
           │  │ transformers │  │ (KMeans clustering)   │  │
           │  │ ~500MB       │  │ ~100MB                │  │
           │  └──────────────┘  └──────────────────────┘  │
           └──────────┬──────────────────────────────────┘
                      │ localhost:11434
           ┌──────────▼──────────────────────────────────┐
           │         Ollama (LLaMA 3.1 8B)               │
           │         ~4.7GB RAM                          │
           │         Port: 11434                         │
           │         (used for future LLM insight gen)   │
           └─────────────────────────────────────────────┘
```

## 3. Data Flow — Weekly Insight

```
User taps "Generate Insight" (mobile app)
    │
    │ POST /api/v1/insights/generate { period: "7d" }
    ▼
┌─ VPS ──────────────────────────────────────────────────┐
│  innerlog-service                                       │
│    │                                                    │
│    ├─ 1. Query check-ins (last 7 days from MongoDB)     │
│    │                                                    │
│    ├─ 2. Try AI engine (15s timeout) ──── Tunnel ──┐    │
│    │                                               │    │
│    │   ┌─ PC ONLINE ─────────────────────────┐     │    │
│    │   │ AI engine receives check-ins        │     │    │
│    │   │ → Sentiment analysis (transformers) │     │    │
│    │   │ → Topic clustering (KMeans)         │     │    │
│    │   │ → Generate 5 insight bullets        │     │    │
│    │   │ → Return { bullets, metrics }       │     │    │
│    │   └─────────────────────────────────────┘     │    │
│    │                                               │    │
│    │   ┌─ PC OFFLINE (fallback) ─────────────┐     │    │
│    │   │ Local JS calculates:                │     │    │
│    │   │ → avg mood score                    │     │    │
│    │   │ → mood label (tích cực/trung bình)  │     │    │
│    │   │ → 3 basic bullets + "AI offline"    │     │    │
│    │   └─────────────────────────────────────┘     │    │
│    │                                                    │
│    ├─ 3. Save Insight to MongoDB                        │
│    └─ 4. Return to mobile app                           │
└─────────────────────────────────────────────────────────┘
```

## 4. Port Map

| Location | Service | Port | Access |
|----------|---------|------|--------|
| VPS | Nginx (SSL) | 443 | Public |
| VPS | innerlog-service | 3000 | Internal (Nginx proxy) |
| VPS | innerlog-ui | 80 (Docker) | Internal (Nginx proxy) |
| VPS | MongoDB | 27017 | Internal only |
| VPS | Redis | 6379 | Internal only |
| Local PC | innerlog-ai-engine | 5000 | Via Cloudflare Tunnel |
| Local PC | Ollama | 11434 | localhost only |

## 5. RAM Usage

| Location | Component | RAM |
|----------|-----------|-----|
| **VPS (4GB total)** | | |
| | innerlog-service | ~200 MB |
| | innerlog-ui (Nginx) | ~50 MB |
| | MongoDB 7 | ~500 MB |
| | Redis 7 | ~100 MB |
| | OS + Docker | ~500 MB |
| | **Tổng VPS** | **~1.35 GB** (dư ~2.65GB) |
| **Local PC (16GB total)** | | |
| | innerlog-ai-engine (FastAPI) | ~200 MB |
| | sentence-transformers | ~500 MB |
| | scikit-learn | ~100 MB |
| | Ollama (LLaMA 3.1 8B) | ~4,700 MB |
| | cloudflared | ~50 MB |
| | **Tổng AI** | **~5.5 GB** (dư ~10.5GB) |

## 6. Privacy Note (GDPR)

InnerLog xử lý dữ liệu sức khỏe tinh thần — nhạy cảm. Hybrid mode có lợi thế:
- AI chạy trên PC cá nhân → dữ liệu check-in KHÔNG gửi qua cloud LLM (Groq/Gemini)
- Ollama chạy local → hoàn toàn offline AI
- Chỉ VPS lưu MongoDB (encrypted at rest recommended)
- Cloudflare Tunnel encrypted end-to-end (HTTPS)
