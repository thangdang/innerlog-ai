# InnerLog AI – Application Flow

## 1. Authentication Flow

```
┌──────────┐    POST /auth/register     ┌──────────────┐
│  Mobile   │ ─────────────────────────► │ innerlog-     │
│  or Admin │    {email, password}       │ service       │
│           │ ◄───────────────────────── │              │
│           │    {user, token,           │  → bcrypt     │
│           │     refreshToken}          │  → JWT sign   │
└──────────┘                            └──────────────┘
```

### Login
1. User nhập email + password
2. Backend verify password (bcrypt compare)
3. Trả về access token (15m) + refresh token (7d)
4. Client lưu token vào localStorage (web) / SharedPreferences (mobile)

### Token Refresh
1. Access token hết hạn → client gọi `POST /auth/refresh`
2. Gửi refreshToken → nhận cặp token mới
3. Tự động, user không cần đăng nhập lại

### Forgot Password
1. `POST /auth/forgot-password` với email
2. Backend tạo reset token (production: gửi email)
3. User dùng token để reset password

---

## 2. Daily Check-in Flow (Core Loop)

```
┌──────────┐   POST /checkins          ┌──────────────┐
│  Mobile   │ ────────────────────────► │ innerlog-     │
│           │   {mood: 4,              │ service       │
│           │    energy: "high",       │              │
│           │    text_note: "...",     │  → Save DB    │
│           │    tags: ["work"]}       │  → Update     │
│           │ ◄──────────────────────── │    Streak     │
│           │   {checkin, streak}       └──────────────┘
└──────────┘
```

### Chi tiết:
1. User mở app → màn hình Check-in
2. Chọn mood (1-5 emoji), energy level, ghi chú tùy chọn
3. Nhấn "Check-in" → gửi API
4. Backend lưu check-in + tự động cập nhật streak:
   - Nếu check-in hôm nay lần đầu → streak +1
   - Nếu bỏ ngày hôm qua → streak reset về 1
   - Cập nhật longest_streak nếu vượt kỷ lục
5. Trả về check-in + streak data → hiển thị streak banner

---

## 3. AI Insight Generation Flow

```
┌──────────┐  POST /insights/generate  ┌──────────────┐  POST /ai/analyze  ┌─────────────────┐
│  Mobile   │ ────────────────────────► │ innerlog-     │ ────────────────► │ innerlog-ai-     │
│  or Admin │                          │ service       │                   │ engine           │
│           │                          │              │                   │                  │
│           │                          │  1. Query     │  3. Sentiment     │  → Rule-based    │
│           │                          │     checkins  │     analysis      │  → Keyword       │
│           │                          │     (7/30/    │  4. Topic         │    clustering    │
│           │                          │      60/90d)  │     clustering    │  → Pattern       │
│           │                          │  2. Send to   │  5. Generate      │    detection     │
│           │ ◄──────────────────────── │     AI engine │     bullets       │  → Bullet gen    │
│           │  {bullets, meta}         │  6. Save      │                   │                  │
│           │                          │     insight   │ ◄──────────────── │                  │
└──────────┘                          └──────────────┘  {bullets, metrics} └─────────────────┘
```

### AI Pipeline chi tiết:
1. **Input**: Danh sách check-ins trong period
2. **Sentiment Analysis**: mood_score → positive/neutral/negative
3. **Topic Clustering**: Keyword matching (VN + EN) → top 3 topics
4. **Insight Generator**: Rule-based bullets (max 5, ≤20 words each)
5. **Metrics**: avg_mood, mood_trend, stress_level, top_topics, positive_score

---

## 4. Silent Coach Flow

```
┌──────────┐  POST /coach/check        ┌──────────────┐  POST /ai/coach   ┌─────────────────┐
│  Mobile   │ ────────────────────────► │ innerlog-     │ ────────────────► │ innerlog-ai-     │
│           │                          │ service       │                   │ engine           │
│           │                          │              │                   │                  │
│           │                          │  1. Query     │  3. Detect:       │                  │
│           │                          │     14 days   │  - mood_drop      │                  │
│           │                          │     checkins  │  - stress_spike   │                  │
│           │                          │  2. Send to   │  - low_energy     │                  │
│           │                          │     AI engine │  - missed_days    │                  │
│           │                          │  4. Save as   │  - burnout_risk   │                  │
│           │ ◄──────────────────────── │  Notification │ ◄──────────────── │                  │
│           │  {alerts, should_notify}  └──────────────┘  {alerts}         └─────────────────┘
└──────────┘
```

### Pattern Detection Rules:
| Pattern | Điều kiện | Severity |
|---------|-----------|----------|
| mood_drop | Mood giảm 3+ ngày liên tục | warning |
| stress_spike | Mood ≤ 2 trong 2+ ngày gần nhất | high |
| low_energy | Energy "low" 3+ ngày trong 5 ngày gần | warning |
| missed_checkins | Gap ≥ 3 ngày không check-in | info |
| burnout_risk | Low mood + low energy ≥ 3/7 ngày | high |

---

## 5. Goal & Micro-task Flow

```
1. Tạo goal: POST /goals {title, category}
2. Thêm task: POST /goals/:id/tasks {title}
3. Toggle task: PUT /goals/:id/tasks/:index/toggle
   → Auto-calculate progress = (done / total) * 100
   → Nếu progress = 100% → status = "completed"
4. Xem goals: GET /goals?status=active
```

---

## 6. Admin Dashboard Flow

```
┌──────────┐  GET /dashboard           ┌──────────────┐
│ Admin UI  │ ────────────────────────► │ innerlog-     │
│ (Angular) │                          │ service       │
│           │ ◄──────────────────────── │              │
│           │  {totalUsers,            │  → Aggregate  │
│           │   premiumUsers,          │    queries    │
│           │   activeUsers,           │              │
│           │   retentionRate,         │              │
│           │   checkinsToday,         │              │
│           │   avgMoodWeek, ...}      │              │
└──────────┘                          └──────────────┘
```

### Admin có thể:
- Xem tổng quan: users, check-ins, mood, retention rate
- Xem chart: daily signups + checkins (30 ngày)
- Quản lý users: filter theo plan (free/premium)
- Xem check-in data, insight history, goals
- Xem top streaks leaderboard

---

## 7. Data Ownership Flow (GDPR)

```
Export:  GET /auth/export    → Trả về toàn bộ data (user, checkins, insights, goals, notifications, streak)
Delete:  DELETE /auth/delete-account → Hard delete tất cả data + tài khoản
```

---

## 8. Monetization Flow

| Feature | Free | Premium |
|---------|------|---------|
| Daily check-in | ✅ | ✅ |
| Streak tracking | ✅ | ✅ |
| Weekly insight (7d) | ✅ | ✅ |
| Long-term insight (30/60/90d) | ❌ | ✅ |
| Silent Coach nâng cao | ❌ | ✅ |
| Unlimited goals | ❌ | ✅ |
| PDF report | ❌ | ✅ |
| Insight comparison | ❌ | ✅ |
