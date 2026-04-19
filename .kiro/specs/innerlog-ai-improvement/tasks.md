# InnerLog AI – Implementation Tasks

> 20 tasks across 5 phases. Priority: AI Engine → Mobile UX → Backend → Admin UI → App Rating.
> Files already partially updated: `model_loader.py` ✅, `sentiment.py` ✅, `clustering.py` ✅

---

## PHASE 1: AI Engine Performance (Python – Free Stack)

### Task 1: Upgrade Insight Generator with Ollama LLM + Rule-Based Fallback
- [x] Rewrite `innerlog-ai/innerlog-ai-engine/app/services/insight_generator.py`: keep existing `_compute_metrics()` logic for metrics calculation, add `_generate_llm_bullets()` async function that calls Ollama `/api/generate` with Vietnamese prompt, JSON array output, max 5 bullets ≤20 words
- [x] Add Ollama config: read `OLLAMA_URL` and `OLLAMA_MODEL` from env (defaults: `http://localhost:11434`, `llama3.1:8b`), timeout 15s, temperature 0.7
- [x] Keep existing rule-based bullet generation as `_generate_rule_bullets()` fallback when Ollama is offline or returns invalid response
- [x] Make `generate_insight_bullets()` async: try LLM first, validate response (must be list of 3-5 strings), fall back to rules on any failure
- [x] Update `innerlog-ai/innerlog-ai-engine/app/routers/analyze.py`: make `analyze()` endpoint async-compatible with the new async insight generator

### Task 2: Upgrade Pattern Detector with Statistical Analysis
- [x] Rewrite `innerlog-ai/innerlog-ai-engine/app/services/pattern_detector.py`: keep all 5 existing patterns (mood_drop, stress_spike, low_energy, missed_checkins, burnout_risk) unchanged
- [x] Add Pattern 6 — mood_declining: use `scipy.stats.linregress` on mood array, alert when slope < -0.15 AND p_value < 0.1, include confidence score (abs r_value)
- [x] Add Pattern 7 — mood_volatile: calculate `numpy.std` of last 7 moods, alert when std > 1.2
- [x] Add Pattern 8 — downtrend_signal: compute 3-day and 7-day moving averages using `numpy.convolve`, alert when MA(3) crosses below MA(7) (bearish crossover)
- [x] Add Pattern 9 — energy_mood_linked: compute `scipy.stats.pearsonr` on last 7 days mood vs energy, alert when correlation > 0.7 with actionable advice about sleep
- [x] Update `detect_patterns()` to require minimum 3 checkins for basic patterns, minimum 5 for statistical patterns

### Task 3: Upgrade Trend Compare with Statistical Depth
- [x] Update `innerlog-ai/innerlog-ai-engine/app/routers/trend.py`: add Welch's t-test (`scipy.stats.ttest_ind`) to determine if mood difference between periods is statistically significant
- [x] Add `significant` boolean and `p_value` float to `TrendResponse` model
- [x] Add `mood_volatility_change` field: compare std of period1 vs period2 moods
- [x] Add `energy_distribution` field: return energy level counts for each period for chart visualization
- [x] Improve summary generation: include significance context ("Sự thay đổi có ý nghĩa thống kê" vs "Chưa đủ dữ liệu để kết luận")

### Task 4: Update AI Engine Main + Health + Requirements
- [x] Update `innerlog-ai/innerlog-ai-engine/app/main.py`: enhance `/health` endpoint to report `model_loaded` (from `model_loader.is_model_loaded()`), `ollama_available` (quick GET to Ollama /api/tags with 2s timeout), and list actual engine versions
- [x] Add CORS middleware to FastAPI app for development
- [x] Update `innerlog-ai/innerlog-ai-engine/requirements.txt`: add `scipy==1.14.0`, remove `transformers==4.44.0` (redundant), keep all other deps
- [x] Add `.env` support: load `OLLAMA_URL`, `OLLAMA_MODEL`, `EMBEDDING_MODEL` from environment using python-dotenv in main.py startup

---

## PHASE 2: Mobile UI/UX (Flutter)

### Task 5: Refactor Navigation — ShellRoute + Persistent Bottom Nav
- [x] Rewrite `innerlog-ai/innerlog-mobile/lib/core/router.dart`: use `StatefulShellRoute.indexedStack` with 4 branches (home, checkin→insights, goals, profile), keep `/login`, `/register`, `/onboarding` as top-level routes outside shell
- [x] Create `innerlog-ai/innerlog-mobile/lib/core/shell_screen.dart`: Scaffold with NavigationBar in bottomNavigationBar, body renders child from ShellRoute, selectedIndex synced with current branch
- [x] Remove NavigationBar from all individual screens: `checkin_screen.dart`, `insight_screen.dart`, `goal_screen.dart`, `profile_screen.dart`
- [x] Add route redirect: if no token in SharedPreferences → redirect to `/login`, if first launch → redirect to `/onboarding`

### Task 6: Add Riverpod State Management + Token Auto-Refresh
- [x] Create `innerlog-ai/innerlog-mobile/lib/core/providers.dart`: `apiClientProvider` (singleton), `authStateProvider` (StateNotifier with token/user), `streakProvider`, `notificationsProvider`
- [x] Rewrite `innerlog-ai/innerlog-mobile/lib/core/api.dart`: make ApiClient a singleton class, add Dio `onError` interceptor for 401 → call `/auth/refresh` with stored refreshToken → retry original request → if refresh fails clear tokens and redirect to `/login`
- [x] Store both `token` and `refreshToken` in SharedPreferences on login/register
- [x] Update all screens to use `ref.watch()` / `ref.read()` instead of creating local `ApiClient()` instances
- [x] Add `generateInsight` method to ApiClient: `POST /insights/generate` with period param

### Task 7: Create Onboarding Flow
- [x] Create `innerlog-ai/innerlog-mobile/lib/onboarding/onboarding_screen.dart`: PageView with 3 pages — (1) Welcome with logo + tagline + illustration, (2) Set reminder time with TimePicker + toggle, (3) First check-in with mood picker + energy selector
- [x] Page indicators (dots) at bottom, "Tiếp tục" button, "Bỏ qua" text button on pages 1-2
- [x] On complete: save `onboarding_done=true` to SharedPreferences, save reminder preference, if mood selected → create first check-in via API, navigate to `/app/home`
- [x] Router guard: check `onboarding_done` flag, redirect to `/onboarding` if false and user is authenticated

### Task 8: Create Home Dashboard Screen
- [x] Create `innerlog-ai/innerlog-mobile/lib/home/home_screen.dart`: scrollable Column with — (1) streak banner (gradient card, current + longest), (2) quick mood row (5 emoji tappable → navigate to checkin with pre-selected mood), (3) latest insight preview card (bullets + "Xem chi tiết" link), (4) goals progress summary card, (5) coach alerts card (latest notification)
- [x] Load data on init: streak from `/checkins/streak`, latest insight from `/insights/latest`, goals from `/goals?status=active`, notifications from `/notifications?unread=true`
- [x] Add pull-to-refresh (RefreshIndicator) to reload all data
- [x] Show notification badge count in AppBar (unread count from notifications API)
- [x] Quick mood tap: navigate to `/app/checkin` with mood pre-filled via query parameter

### Task 9: Upgrade Check-in Screen — Scrollable, Tags, Success Animation
- [x] Wrap Check-in screen body in `SingleChildScrollView` to prevent overflow on small screens
- [x] Add tags chip selector below note field: preset tags `['work', 'study', 'health', 'relationship', 'finance', 'mood']`, multi-select, pass selected tags to `createCheckin()` API call
- [x] Add success animation after check-in: replace text message with animated checkmark (AnimatedContainer or Lottie-style), auto-dismiss after 2s
- [x] Add pull-to-refresh to reload streak data
- [x] Show streak milestone celebration: if `current_streak` is 7, 30, or 100 after check-in → show congratulation dialog with emoji

### Task 10: Upgrade Insight Screen — Charts + History
- [x] Add mood trend line chart at top of Insight screen using `fl_chart` `LineChart`: x-axis = dates, y-axis = mood (1-5), data from `/checkins/stats`
- [x] Add tab bar: "Mới nhất" (current latest insight) | "Lịch sử" (list of past insights from `/insights/history`)
- [x] History tab: ListView of insight cards showing period, date, bullet preview, mood badge
- [x] Add "Tạo insight mới" FloatingActionButton: call `POST /insights/generate` with period selector (7d default, 30d/60d/90d for premium), show loading, refresh on complete
- [x] Add pull-to-refresh on both tabs

### Task 11: Create Notification Screen + Error Boundary
- [x] Create `innerlog-ai/innerlog-mobile/lib/notification/notification_screen.dart`: ListView of notifications from `/notifications`, each item shows icon (by type), title, message, timestamp, read/unread styling
- [x] Tap notification → mark as read via `PUT /notifications/:id/read`
- [x] Add "Đánh dấu tất cả đã đọc" button in AppBar
- [x] Update `innerlog-ai/innerlog-mobile/lib/main.dart`: wrap `runApp` in `runZonedGuarded`, set `FlutterError.onError` to log errors (print to console for now), show user-friendly error widget instead of red screen
- [x] Add form validation to login_screen.dart and register_screen.dart: email format regex, password min 6 chars, display inline error text below fields

---

## PHASE 3: Backend Hardening

### Task 12: Add Input Validation to All Routes
- [x] Add validation to `innerlog-ai/innerlog-service/src/routes/auth.ts`: register (email isEmail, password isLength min 6, display_name optional isString), login (email isEmail, password notEmpty), change-password (current_password notEmpty, new_password isLength min 6)
- [x] Add validation to `innerlog-ai/innerlog-service/src/routes/checkins.ts`: create (mood_score isInt 1-5, energy_level isIn ['low','normal','high'], text_note optional isLength max 500)
- [x] Add validation to `innerlog-ai/innerlog-service/src/routes/goals.ts`: create (title notEmpty isLength max 200, category isIn ['study','work','health','finance','other'])
- [x] Add validation to `innerlog-ai/innerlog-service/src/routes/insights.ts`: generate (period isIn ['7d','30d','60d','90d'])
- [x] Create shared validation handler helper in `innerlog-ai/innerlog-service/src/middleware/validate.ts`: extract `validationResult`, return 400 with formatted errors array

### Task 13: Add Admin Role + Pagination + Subscription Enforcement
- [x] Add `role` field to User model in `innerlog-ai/innerlog-service/src/models/User.ts`: `role: { type: String, enum: ['user', 'admin'], default: 'user' }`, include role in JWT payload in auth.ts `generateTokens()`
- [x] Create `requireAdmin` middleware in `innerlog-ai/innerlog-service/src/middleware/auth.ts`: check `req.userRole === 'admin'`, return 403 if not
- [x] Apply `requireAdmin` to all routes in `innerlog-ai/innerlog-service/src/routes/dashboard.ts`
- [x] Add pagination to `GET /checkins` in `innerlog-ai/innerlog-service/src/routes/checkins.ts`: accept `page` (default 1) and `limit` (default 50, max 100) query params, return `{ data, total, page, limit, hasMore }`
- [ ] Add `requirePremium` middleware: check `user.plan === 'premium'` for premium features (30d/60d/90d insights, insight compare), return 403 with upgrade message

### Task 14: Add Notification Settings + Dark Mode Preference to User Model
- [x] Add fields to User model in `innerlog-ai/innerlog-service/src/models/User.ts`: `theme: { type: String, enum: ['light', 'dark', 'system'], default: 'system' }`, `notify_coach: { type: Boolean, default: true }`, `notify_reminder: { type: Boolean, default: true }`, `notify_insight: { type: Boolean, default: true }`
- [x] Add these fields to the `allowed` array in `PUT /auth/profile` route so they can be updated
- [ ] Update coach route in `innerlog-ai/innerlog-service/src/routes/coach.ts`: check `user.notify_coach` before saving notifications — skip if disabled
- [ ] Add `GET /api/v1/auth/settings` endpoint: return user's notification preferences + theme preference
- [ ] Add `PUT /api/v1/auth/settings` endpoint: update notification + theme preferences

---

## PHASE 4: Admin UI Enhancement (Angular)

### Task 15: Add Dashboard Charts — Line Chart for Signups/Checkins
- [x] Add `ng2-charts` and `chart.js` to `innerlog-ai/innerlog-ui/package.json` dependencies
- [x] Import `NgChartsModule` in `innerlog-ai/innerlog-ui/src/app/innerlog.module.ts`
- [x] Update `innerlog-ai/innerlog-ui/src/app/InnerLog/dashboard/dashboard.component.ts`: add `chartData` and `chartOptions` properties, call `api.getDashboardChart(30)` on init, map response to Chart.js line dataset format (labels, signups series, checkins series)
- [x] Update `innerlog-ai/innerlog-ui/src/app/InnerLog/dashboard/dashboard.component.html`: add `<canvas baseChart>` line chart below KPI cards row, add top streaks leaderboard card calling `api.getTopStreaks()`
- [x] Style chart card: card wrapper with header "Hoạt động 30 ngày", responsive height

### Task 16: Add Date Filter on Checkins + Insight Generation Trigger
- [x] Update `innerlog-ai/innerlog-ui/src/app/InnerLog/checkins/checkins.component.ts`: add `fromDate` and `toDate` properties, `loadCheckins()` method that calls `api.getCheckins(from, to)`
- [x] Update `innerlog-ai/innerlog-ui/src/app/InnerLog/checkins/checkins.component.html`: add date input row above table with from/to date pickers and "Lọc" button
- [x] Update `innerlog-ai/innerlog-ui/src/app/InnerLog/insights/insights.component.ts`: add `generateInsight(period)` method calling `api.generateInsight(period)`
- [x] Update `innerlog-ai/innerlog-ui/src/app/InnerLog/insights/insights.component.html`: add "Tạo Insight" button with period dropdown (7d, 30d), refresh list after generation
- [x] Add loading spinner during API calls on both pages

---

## PHASE 5: App Store Rating Optimization

### Task 17: Add Crash Handling + Offline Check-in Support
- [x] Update `innerlog-ai/innerlog-mobile/lib/main.dart`: wrap `runApp` in `runZonedGuarded` with error logging, set `FlutterError.onError` to capture framework errors, show `MaterialApp` with error fallback widget on uncaught errors
- [x] Add offline check-in queue: when `createCheckin()` throws DioException (connection error), save check-in to SharedPreferences as JSON list under key `offline_checkins`
- [x] Add sync mechanism: on app startup and on successful API call, check `offline_checkins` list, POST each to server, remove from local queue on success
- [x] Show offline indicator: when Dio interceptor detects no connection, show SnackBar "Đang offline — check-in sẽ được đồng bộ khi có mạng"

### Task 18: Add In-App Rating Prompt
- [x] Create `innerlog-ai/innerlog-mobile/lib/core/rating_service.dart`: track conditions — streak >= 7 days, last insight was positive (avg_mood >= 3.5), not shown in last 30 days (check SharedPreferences `last_rating_prompt` timestamp)
- [x] Show rating dialog: "Bạn thấy InnerLog hữu ích? 🌟" with buttons "Đánh giá ngay" (open store URL), "Để sau" (dismiss, can show again), "Không hiển thị nữa" (set `rating_never_show` flag)
- [x] Trigger check: call `checkAndShowRating()` after successful check-in on home screen, after viewing insight with positive mood
- [x] Never trigger after coach alert with severity "high" (user is stressed)

### Task 19: Add Localization Support (Vietnamese + English)
- [x] Create `innerlog-ai/innerlog-mobile/lib/core/l10n/` directory with `app_vi.arb` and `app_en.arb` files containing all UI strings (screen titles, button labels, error messages, onboarding text)
- [x] Update `innerlog-ai/innerlog-mobile/pubspec.yaml`: add `flutter_localizations` dependency, enable `generate: true` in flutter section
- [x] Update `innerlog-ai/innerlog-mobile/lib/main.dart`: add `localizationsDelegates` and `supportedLocales` to MaterialApp.router
- [x] Update Profile screen: add language selector (Vietnamese / English), save preference to SharedPreferences and User profile API
- [x] Replace all hardcoded Vietnamese strings across screens with localization keys

### Task 20: Add Accessibility + Performance Polish
- [x] Add `Semantics` widgets to key interactive elements across all screens: mood emoji buttons (label: "Mood score X"), energy selector, navigation items, action buttons
- [x] Ensure all tappable areas have minimum 44x44px touch target (check GestureDetector/InkWell sizing)
- [x] Add `loading="lazy"` equivalent: use `FutureBuilder` with skeleton placeholders instead of bare `CircularProgressIndicator` on all data-loading screens
- [x] Review and ensure proper color contrast ratios for text on gradient backgrounds (streak banner, buttons)
- [x] Add `resizeToAvoidBottomInset: true` on screens with text input to handle keyboard properly
