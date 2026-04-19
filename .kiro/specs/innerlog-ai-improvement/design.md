# InnerLog AI – Improvement Design Document

> Technical design cho 5 trụ cột cải tiến: AI Engine, Mobile UX, App Rating, Backend, Admin UI.
> Ref: #[[file:innerlog-ai/spec/REVIEW_AND_IMPROVEMENT_PLAN.md]] | #[[file:innerlog-ai/docs/01-architecture.md]]

---

## 1. AI Engine Design (Python – 100% Free)

### 1.1 Upgraded AI Pipeline

```
Check-ins
   ↓
┌──────────────────────────────────────┐
│ Sentiment Analysis (UPGRADED)        │
│ Primary: sentence-transformers       │
│   paraphrase-multilingual-MiniLM     │
│   Cosine similarity vs anchor phrases│
│ Hybrid: text (60%) + mood (40%)      │
│ Fallback: mood_score threshold only  │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ Topic Clustering (UPGRADED)          │
│ Primary: KMeans on embeddings        │
│   Auto k (2-5) via silhouette score  │
│   Label via topic anchor similarity  │
│ Fallback: keyword matching (VN+EN)   │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ Insight Generator (UPGRADED)         │
│ Primary: Ollama LLM (local, free)    │
│   LLaMA 3.1 8B / Mistral 7B         │
│   Vietnamese prompt, JSON output     │
│   Max 5 bullets, ≤20 words each      │
│ Fallback: rule-based templates       │
└──────────────┬───────────────────────┘
               ↓
┌──────────────────────────────────────┐
│ Pattern Detector (UPGRADED)          │
│ Existing: 5 threshold-based rules    │
│ NEW: linear regression mood trend    │
│ NEW: volatility (rolling std)        │
│ NEW: MA crossover (3d vs 7d)         │
│ NEW: energy-mood Pearson correlation │
│ Uses: numpy + scipy.stats            │
└──────────────────────────────────────┘
```

### 1.2 Model Management

```python
# Singleton lazy-loader pattern (already implemented)
# File: app/services/model_loader.py

get_embedding_model()  # Returns cached SentenceTransformer
is_model_loaded()      # Status check for health endpoint

# Key design decisions:
# - Lazy load on first request (not at startup) → fast cold start
# - Batch encode texts (not one-by-one) → 3-5x faster
# - Anchor embeddings cached in memory → no re-computation
# - Graceful fallback when model fails to load
```

### 1.3 Ollama Integration Design

```
┌─────────────────────────────────────┐
│ insight_generator.py                │
│                                     │
│ generate_insight_bullets()          │
│   ├─ compute metrics (rule-based)   │
│   ├─ try: Ollama LLM               │
│   │   ├─ build Vietnamese prompt    │
│   │   ├─ POST /api/generate         │
│   │   ├─ parse JSON array response  │
│   │   └─ validate: 3-5 bullets      │
│   └─ except: rule-based fallback    │
│                                     │
│ Ollama config:                      │
│   URL: env OLLAMA_URL               │
│   Model: env OLLAMA_MODEL           │
│   Timeout: 15s                      │
│   Temperature: 0.7                  │
│   Max tokens: 300                   │
└─────────────────────────────────────┘
```

### 1.4 Statistical Pattern Detection Design

```python
# New patterns using scipy.stats + numpy:

# 1. Linear regression on mood array
#    slope < -0.15 AND p_value < 0.1 → "mood_declining" alert

# 2. Rolling std of last 7 moods
#    std > 1.2 → "mood_volatile" alert

# 3. Moving average crossover
#    MA(3) crosses below MA(7) → "downtrend_signal" alert

# 4. Pearson correlation (mood vs energy)
#    r > 0.7 → "energy_mood_linked" insight

# 5. Keep all 5 existing patterns:
#    mood_drop, stress_spike, low_energy, missed_checkins, burnout_risk
```

### 1.5 Updated File Structure

```
innerlog-ai-engine/app/
├── main.py                    # FastAPI app + health endpoint (UPDATED)
├── routers/
│   ├── analyze.py             # /ai/analyze (unchanged)
│   ├── coach.py               # /ai/coach (unchanged)
│   └── trend.py               # /ai/trend-compare (UPDATED)
└── services/
    ├── model_loader.py        # NEW: singleton embedding model
    ├── sentiment.py           # UPDATED: hybrid NLP + mood
    ├── clustering.py          # UPDATED: embedding KMeans + keyword fallback
    ├── insight_generator.py   # UPDATED: Ollama LLM + rule fallback
    └── pattern_detector.py    # UPDATED: statistical + threshold patterns
```

### 1.6 Updated requirements.txt

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
scipy==1.14.0              # NEW: statistical analysis
# Note: torch is auto-installed by sentence-transformers
# Note: transformers removed (included in sentence-transformers)
```

---

## 2. Mobile UI/UX Design (Flutter)

### 2.1 Navigation Architecture Refactor

```
BEFORE (current):
  GoRouter flat routes + NavigationBar copy-pasted in each screen

AFTER:
  GoRouter with StatefulShellRoute:
  
  /login
  /register
  /onboarding
  /app (ShellRoute with persistent NavigationBar)
    ├── /app/home        ← NEW: dashboard
    ├── /app/checkin
    ├── /app/insights
    ├── /app/goals
    └── /app/profile
```

### 2.2 State Management with Riverpod

```dart
// Providers (new file: lib/core/providers.dart)

final apiClientProvider = Provider((ref) => ApiClient());

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

final userProvider = FutureProvider((ref) async {
  return ref.read(apiClientProvider).getMe();
});

final streakProvider = FutureProvider((ref) async {
  return ref.read(apiClientProvider).getStreak();
});
```

### 2.3 Home Dashboard Screen Design

```
┌─────────────────────────────────┐
│ InnerLog          🔔 (3)        │  ← App bar with notification badge
├─────────────────────────────────┤
│ ┌─────────────────────────────┐ │
│ │ 🔥 12 ngày streak  🏆 30   │ │  ← Streak banner (gradient)
│ └─────────────────────────────┘ │
│                                 │
│ Hôm nay bạn thế nào?           │
│ [😢] [😟] [😐] [🙂] [😄]      │  ← Quick mood (tap → go to checkin)
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 📊 Insight tuần này         │ │
│ │ • Tâm trạng: tích cực 3.8  │ │
│ │ • Xu hướng: cải thiện ↑     │ │
│ │ [Xem chi tiết →]            │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🎯 Goals: 2/5 hoàn thành   │ │
│ │ ████████░░░░ 40%            │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ 🤖 Silent Coach              │ │
│ │ "Tâm trạng giảm liên tục.  │ │
│ │  Hãy dành thời gian..."     │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 🏠  📊  🎯  👤                  │  ← Persistent bottom nav
└─────────────────────────────────┘
```

### 2.4 Onboarding Flow Design

```
Screen 1: Welcome
  - InnerLog logo + tagline
  - "Theo dõi cảm xúc, AI phân tích xu hướng"
  - Illustration
  - [Tiếp tục] [Bỏ qua]

Screen 2: Set Reminder
  - "Bạn muốn check-in lúc mấy giờ?"
  - Time picker (default 21:00)
  - Toggle: Bật nhắc nhở hàng ngày
  - [Tiếp tục]

Screen 3: First Check-in
  - "Hôm nay bạn cảm thấy thế nào?"
  - Mood picker (emoji 1-5)
  - Energy selector
  - Optional note
  - [Bắt đầu hành trình]
```

### 2.5 Token Auto-Refresh Design

```dart
// In ApiClient Dio interceptor:
_dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      // Try refresh
      final refreshToken = prefs.getString('refreshToken');
      if (refreshToken != null) {
        try {
          final res = await _refreshDio.post('/auth/refresh',
            data: {'refreshToken': refreshToken});
          await prefs.setString('token', res.data['token']);
          await prefs.setString('refreshToken', res.data['refreshToken']);
          // Retry original request
          final retryRes = await _dio.fetch(error.requestOptions);
          handler.resolve(retryRes);
          return;
        } catch (_) {}
      }
      // Refresh failed → logout
      await prefs.clear();
      appRouter.go('/login');
    }
    handler.next(error);
  },
));
```

### 2.6 Updated File Structure

```
innerlog-mobile/lib/
├── main.dart                    # UPDATED: error boundary
├── core/
│   ├── api.dart                 # UPDATED: token refresh, singleton
│   ├── router.dart              # UPDATED: ShellRoute
│   ├── theme.dart               # (unchanged)
│   └── providers.dart           # NEW: Riverpod providers
├── auth/
│   ├── login_screen.dart        # UPDATED: validation
│   └── register_screen.dart     # UPDATED: validation
├── onboarding/
│   └── onboarding_screen.dart   # NEW
├── home/
│   └── home_screen.dart         # NEW: dashboard
├── checkin/
│   └── checkin_screen.dart      # UPDATED: scrollable, tags, animation
├── insight/
│   └── insight_screen.dart      # UPDATED: charts, history
├── goal/
│   └── goal_screen.dart         # UPDATED: pull-to-refresh
├── notification/
│   └── notification_screen.dart # NEW
└── profile/
    └── profile_screen.dart      # UPDATED: settings
```

---

## 3. Backend Enhancement Design

### 3.1 Input Validation Middleware

```typescript
// Using express-validator (already in package.json)
// Pattern: validation chains in each route file

import { body, query, validationResult } from 'express-validator';

// Reusable validation handler
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  next();
};

// Example: POST /checkins
router.post('/',
  authMiddleware,
  body('mood_score').isInt({ min: 1, max: 5 }),
  body('energy_level').isIn(['low', 'normal', 'high']),
  body('text_note').optional().isString().isLength({ max: 500 }),
  validate,
  async (req, res) => { ... }
);
```

### 3.2 Admin Role Middleware

```typescript
// New middleware: requireAdmin
export function requireAdmin(req: AuthRequest, res: Response, next: NextFunction): void {
  if (req.userRole !== 'admin') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
}

// User model: add role field
role: { type: String, enum: ['user', 'admin'], default: 'user' }

// JWT payload: include role
jwt.sign({ id: userId, role: user.role }, ...)
```

### 3.3 Pagination Design

```typescript
// Standard pagination for list endpoints
interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  hasMore: boolean;
}

// GET /checkins?page=1&limit=50&from=&to=
const page = parseInt(req.query.page) || 1;
const limit = Math.min(parseInt(req.query.limit) || 50, 100);
const skip = (page - 1) * limit;
```

---

## 4. Admin UI Enhancement Design

### 4.1 Dashboard Charts

```
┌─────────────────────────────────────────────────┐
│ KPI Cards (existing, unchanged)                 │
├─────────────────────────────────────────────────┤
│ ┌──────────────────────┐ ┌────────────────────┐ │
│ │ Daily Signups &      │ │ Top Streaks        │ │
│ │ Checkins (30 days)   │ │ Leaderboard        │ │
│ │ [Line Chart]         │ │ 1. user@... 🔥45   │ │
│ │                      │ │ 2. user@... 🔥32   │ │
│ └──────────────────────┘ └────────────────────┘ │
└─────────────────────────────────────────────────┘
```

- Use Chart.js via ng2-charts (add to package.json)
- Data from existing API: `GET /dashboard/chart` + `GET /dashboard/streaks`

### 4.2 Date Range Filter on Checkins

```html
<!-- Add to checkins.component.html -->
<div class="row mb-3">
  <div class="col-md-4">
    <input type="date" [(ngModel)]="fromDate" (change)="loadCheckins()">
  </div>
  <div class="col-md-4">
    <input type="date" [(ngModel)]="toDate" (change)="loadCheckins()">
  </div>
</div>
```

---

## 5. Architecture Summary

### Dependencies Added

| Component | Package | Purpose |
|-----------|---------|---------|
| AI Engine | scipy==1.14.0 | Statistical pattern detection |
| AI Engine | (remove transformers) | Redundant with sentence-transformers |
| Admin UI | ng2-charts + chart.js | Dashboard charts |
| Mobile | (no new deps) | All deps already in pubspec.yaml |
| Backend | (no new deps) | express-validator already in package.json |

### Cost Impact
No additional cost. All improvements use existing free/open-source tools.
Total infrastructure remains ~$24/month.
