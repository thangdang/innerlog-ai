# InnerLog AI – Comprehensive Improvement Requirements

> Mục tiêu: Nâng cấp toàn diện InnerLog AI về UI/UX, App Store rating, chức năng, và AI performance (100% free Python stack).
> Target: Người trẻ Việt Nam – dùng lâu dài 3–5 năm
> Ref: #[[file:innerlog-ai/spec/INNERLOG_FULL_FUNCTIONALITY_C.md]] | #[[file:innerlog-ai/spec/INNERLOG_TECH.md]] | #[[file:innerlog-ai/spec/REVIEW_AND_IMPROVEMENT_PLAN.md]]

---

## Requirement 1: AI Engine Performance – Real NLP + LLM Integration (Free Python Stack)

### User Story
Là người dùng InnerLog, tôi muốn AI phân tích cảm xúc chính xác từ ghi chú tiếng Việt, phát hiện xu hướng thông minh, và đưa ra insight cá nhân hóa — không phải template cứng nhắc.

### Acceptance Criteria
1. Sentiment analysis phải sử dụng sentence-transformers (`paraphrase-multilingual-MiniLM-L12-v2`) để phân tích text_note tiếng Việt, kết hợp mood_score (hybrid: text 60% + mood 40%), fallback về mood-only khi model unavailable
2. Topic clustering phải dùng KMeans trên sentence embeddings khi có ≥4 text notes, auto-determine k (2-5) bằng silhouette score, label clusters bằng cosine similarity với topic anchors, fallback về keyword matching
3. Insight generator phải tích hợp Ollama (LLaMA 3.1 8B hoặc Mistral 7B — free, local) để tạo bullet insight tự nhiên bằng tiếng Việt, max 5 bullets ≤20 từ, fallback về rule-based khi Ollama offline
4. Pattern detector phải thêm statistical analysis: linear regression cho mood trend, volatility detection (rolling std), moving average crossover, energy-mood correlation (Pearson), giữ lại 5 pattern cũ
5. Model phải lazy-load singleton, batch encode cho performance, cold start ≤5s, response time ≤500ms (ML) / ≤3s (LLM)
6. Health endpoint phải report model load status và Ollama availability
7. Thêm scipy vào requirements.txt cho statistical analysis, loại bỏ transformers (sentence-transformers đã include)
8. Trend compare endpoint phải thêm statistical significance test và chi tiết hơn cho visualization

---

## Requirement 2: Mobile UI/UX – Retention-Focused Experience

### User Story
Là người dùng trẻ Việt Nam, tôi muốn app đẹp, mượt, có onboarding rõ ràng, home dashboard tổng quan, và các micro-interaction khiến tôi muốn quay lại mỗi ngày.

### Acceptance Criteria
1. Thêm onboarding flow 3 màn hình cho user mới: giới thiệu InnerLog → set reminder time → first check-in, skip option, chỉ hiện 1 lần
2. Thêm Home Dashboard screen: streak banner, today's mood summary, latest insight preview, coach alerts badge, quick check-in button
3. Refactor NavigationBar: dùng ShellRoute với StatefulShellRoute thay vì copy-paste NavigationBar trong mỗi screen
4. Thêm token auto-refresh trong Dio interceptor: khi nhận 401 → gọi /auth/refresh → retry request, nếu refresh fail → redirect login
5. Thêm Riverpod providers cho ApiClient (singleton), auth state, user profile — thay vì tạo ApiClient mới mỗi screen
6. Thêm form validation: email format, password min 6 chars, required fields — hiển thị error inline
7. Thêm mood heatmap calendar UI sử dụng fl_chart hoặc custom widget, data từ API /checkins/heatmap
8. Thêm mood trend line chart trên Insight screen sử dụng fl_chart, data từ API /checkins/stats
9. Thêm tags UI trên Check-in screen: chip selector với preset tags (work, study, health, relationship, finance)
10. Thêm Notification/Coach alerts screen: list notifications từ API, mark as read, unread badge trên nav
11. Thêm pull-to-refresh cho tất cả list screens
12. Thêm error boundary: FlutterError.onError + runZonedGuarded trong main.dart
13. Check-in screen phải scrollable (SingleChildScrollView) để không overflow trên màn hình nhỏ

---

## Requirement 3: App Store / CH Play Rating Optimization

### User Story
Là product owner, tôi muốn app đạt rating 4.5+ trên cả App Store và CH Play để tăng organic downloads.

### Acceptance Criteria
1. Thêm in-app rating prompt: trigger sau 7-day streak hoặc sau khi xem positive insight, không hiện khi user đang stress, không hiện lại trong 30 ngày
2. Thêm crash handling: FlutterError.onError + runZonedGuarded log errors, graceful error screens thay vì red screen
3. Thêm offline check-in support: lưu check-in vào local storage (SharedPreferences hoặc SQLite) khi offline, sync khi có mạng
4. Thêm streak celebration: animation/confetti khi đạt milestone (7, 30, 100 ngày)
5. Thêm localization support: intl package, Vietnamese (default) + English, language toggle trong Profile
6. App startup phải có splash screen animation (logo fade-in), load time < 2s
7. Tất cả error messages phải bằng tiếng Việt, thân thiện, có gợi ý hành động cụ thể
8. Thêm accessibility: Semantics widgets cho screen readers, minimum touch target 44x44px, proper contrast ratios

---

## Requirement 4: Backend Functionality Gaps

### User Story
Là developer, tôi muốn backend robust, secure, và implement đầy đủ các features trong spec Level C mà hiện tại còn thiếu.

### Acceptance Criteria
1. Thêm input validation (Zod hoặc express-validator) cho tất cả routes: auth, checkins, goals, insights — reject invalid data với error messages rõ ràng
2. Thêm admin role enforcement: middleware `requireAdmin` check userRole === 'admin', protect tất cả /dashboard/* routes
3. Thêm pagination cho GET /checkins: default limit 50, support page/limit query params
4. Thêm scheduled jobs (node-cron): weekly insight auto-generation (mỗi Chủ nhật), check-in reminder push
5. Thêm notification settings per-type trong User model: coach_notify, reminder_notify, insight_notify — boolean toggles
6. Thêm dark/light mode preference trong User model, sync với mobile app
7. Fix forgot-password: tích hợp email service (nodemailer + Gmail hoặc SendGrid free tier) thay vì return dev token
8. Thêm subscription enforcement middleware: check user.plan trước khi cho access premium features (30/60/90d insight, unlimited goals, PDF report)

---

## Requirement 5: Admin Dashboard Enhancement

### User Story
Là admin/product owner, tôi muốn dashboard có charts trực quan, date filters, và khả năng quản lý users/content hiệu quả.

### Acceptance Criteria
1. Thêm line charts trên Dashboard: daily signups + daily checkins (30 ngày), sử dụng ng2-charts/Chart.js
2. Thêm date range filter trên Checkins page: from/to date pickers, gọi API với query params
3. Thêm insight generation trigger: admin có thể generate insight cho bất kỳ user nào
4. Thêm notification management page: xem tất cả coach notifications, filter by type/user
5. Thêm top streaks leaderboard widget trên Dashboard
6. Thêm admin role guard trên Angular routing: redirect về login nếu không phải admin
