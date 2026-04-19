# InnerLog AI – Architecture

## Tổng quan hệ thống

InnerLog AI là ứng dụng theo dõi sức khỏe tinh thần cá nhân, sử dụng AI phân tích hành vi và đưa ra insight thông minh. Hệ thống gồm 4 thành phần chính.

## Kiến trúc tổng thể

```
┌─────────────────┐     ┌─────────────────┐
│  innerlog-mobile │     │   innerlog-ui    │
│  (Flutter App)   │     │  (Angular Admin) │
│  Android + iOS   │     │  ArchitectUI     │
└────────┬────────┘     └────────┬────────┘
         │  REST API              │  REST API
         └──────────┬─────────────┘
                    │
         ┌──────────▼──────────┐
         │   innerlog-service   │
         │  Express.js + TS     │
         │  JWT Auth            │
         │  Port: 3000          │
         └──────────┬──────────┘
                    │
          ┌─────────┼─────────┐
          │         │         │
   ┌──────▼──┐ ┌───▼───┐ ┌──▼──────────────┐
   │ MongoDB  │ │ Redis │ │ innerlog-ai-engine│
   │ Port:    │ │ Port: │ │ FastAPI + Python  │
   │ 27017    │ │ 6379  │ │ Port: 5000        │
   └──────────┘ └───────┘ └─────────────────┘
```

## Thành phần chi tiết

### 1. innerlog-service (Backend API)

| Thuộc tính | Giá trị |
|------------|---------|
| Framework | Express.js 4.x |
| Ngôn ngữ | TypeScript 5.x |
| Runtime | Node.js 20+ |
| Database | MongoDB 7 (Mongoose 8) |
| Cache | Redis 7 |
| Auth | JWT (access + refresh token) |
| Security | Helmet, CORS, Rate Limit |

**Models:**
- `User` — tài khoản, profile, plan (free/premium)
- `Checkin` — mood (1-5), energy, note, tags
- `Insight` — AI-generated bullets + metrics
- `Goal` — mục tiêu + micro-tasks + auto-progress
- `Streak` — chuỗi check-in liên tục
- `Notification` — coach alerts, reminders

**Routes:**
| Route | Mô tả |
|-------|-------|
| `/api/v1/auth/*` | Register, login, refresh, profile, change password, forgot password, export data, delete account |
| `/api/v1/checkins/*` | CRUD check-in, streak, heatmap, stats/trends |
| `/api/v1/insights/*` | Generate AI insight, latest, history, compare |
| `/api/v1/goals/*` | CRUD goals, toggle micro-task, add task |
| `/api/v1/coach/*` | Silent Coach — gọi AI engine phát hiện pattern (cache 1h, fallback local JS) |
| `/api/v1/notifications/*` | List, mark read, mark all read |
| `/api/v1/dashboard/*` | Admin overview, user list, chart data, top streaks, retention rate |

### 2. innerlog-ai-engine (AI Service)

| Thuộc tính | Giá trị |
|------------|---------|
| Framework | FastAPI |
| Ngôn ngữ | Python 3.11 |
| ML | scikit-learn, sentence-transformers |
| LLM | Ollama + LLaMA 3.1 8B (self-hosted, free) |

**AI Pipeline:**
```
Check-ins → Sentiment Analysis → Topic Clustering → Pattern Detection → Insight Generator
```

**Endpoints:**
| Endpoint | Mô tả |
|----------|-------|
| `POST /ai/analyze` | Phân tích check-ins → bullets + metrics |
| `POST /ai/coach` | Phát hiện pattern: mood drop, stress spike, burnout, missed days |
| `POST /ai/trend-compare` | So sánh 2 giai đoạn |

**Pattern Detection (Silent Coach):**
- Mood giảm liên tục 3+ ngày
- Stress spike (mood ≤ 2 nhiều ngày)
- Low energy streak
- Missed check-ins (gap ≥ 3 ngày)
- Burnout risk (low mood + low energy combo)

### 3. innerlog-ui (Admin Dashboard)

| Thuộc tính | Giá trị |
|------------|---------|
| Framework | Angular 21 |
| UI Template | ArchitectUI Free (Bootstrap 5) |
| State | NgRx |
| Charts | Chart.js + ng2-charts |

**Admin Pages:**
- Dashboard — tổng quan: users, check-ins, mood, retention
- Users — danh sách user, filter theo plan
- Check-ins — xem dữ liệu check-in
- Insights — lịch sử AI insight
- Goals — quản lý mục tiêu
- Login — admin authentication

### 4. innerlog-mobile (Flutter App)

| Thuộc tính | Giá trị |
|------------|---------|
| Framework | Flutter 3.x |
| State | Riverpod |
| HTTP | Dio |
| Router | go_router |
| Charts | fl_chart |

**Screens:**
- Login / Register
- Daily Check-in (mood emoji, energy, note + streak banner)
- Weekly Insight (AI bullets + metrics)
- Goals (micro-task toggle, auto-progress)
- Profile (edit, change password, export data, delete account)

## Database Schema

```
users {
  _id, email, password_hash, display_name, avatar,
  age, gender, timezone, language, plan,
  reminder_enabled, reminder_time, created_at
}

checkins {
  _id, user_id, mood_score(1-5), energy_level,
  text_note, tags[], created_at
}
Index: user_id + created_at

insights {
  _id, user_id, period(7d/30d/60d/90d),
  bullets[], meta{avg_mood, mood_trend, stress_level, top_topics, positive_score},
  created_at
}

goals {
  _id, user_id, title, category,
  tasks[{title, done}], progress(0-100),
  status(active/completed/abandoned), created_at, updated_at
}

streaks {
  _id, user_id(unique), current_streak, longest_streak,
  last_checkin_date, total_checkins, updated_at
}

notifications {
  _id, user_id, type(coach/reminder/insight/streak/system),
  title, message, read, created_at
}
```

## Security

- JWT access token (15 phút) + refresh token (7 ngày)
- Password hashed với bcrypt (12 rounds)
- Helmet HTTP headers
- Rate limiting (100 req / 15 phút)
- CORS enabled
- Không social feed, không public data
- AI chạy local (Ollama), không gửi data ra ngoài
- GDPR: export data + hard delete account

## Hybrid Deployment (Primary Target)

Kiến trúc hybrid cho giai đoạn MVP — AI engine chạy trên Local PC, services trên VPS $24.

- **VPS ($24/mo)**: innerlog-service + innerlog-ui + MongoDB + Redis
- **Local PC (16GB)**: innerlog-ai-engine (sentiment + clustering + Ollama)
- **Kết nối**: Cloudflare Tunnel (HTTPS)
- **Fallback**: PC offline → local JS fallback (basic mood analysis + pattern detection)
- **Cache**: Redis cache cho insight (6h), coach (1h) — tránh gọi AI lặp lại
- **GDPR**: AI chạy trên PC cá nhân → dữ liệu sức khỏe tinh thần không gửi qua cloud LLM
- **Chi phí**: ~$26/tháng (~650,000đ)

Xem chi tiết: [Deploy Guide](./04-deploy.md) | [Network Diagram](./05-hybrid-network.md)

### Code Files (Hybrid)

| File | Purpose |
|------|---------|
| `src/services/cache.ts` | Redis cache (insight 6h, coach 1h) |
| `src/routes/insights.ts` | Cache check + local JS fallback |
| `src/routes/coach.ts` | Cache check + local JS fallback |
