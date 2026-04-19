# InnerLog AI — Requirements

> Based on: #[[file:spec/REVIEW_AND_IMPROVEMENT_PLAN.md]] + #[[file:spec/INNERLOG_FULL_FUNCTIONALITY_C.md]]

---

## REQ-1: Mobile App Foundation & Navigation
Refactor the Flutter mobile app to use ShellRoute for persistent bottom navigation, implement Riverpod state management as a singleton pattern for ApiClient and auth state, add Dio interceptor for automatic JWT token refresh before expiry, and wrap the app in error boundaries (FlutterError.onError + runZonedGuarded) to prevent unhandled crashes.

## REQ-2: Onboarding & Home Dashboard
Add a 3-screen onboarding flow (value prop, set reminder time, first check-in prompt) shown only on first launch. Create a Home Dashboard screen as the default landing page after login showing: current streak banner, today's mood summary, latest insight preview, unread coach alerts count, and quick check-in button.

## REQ-3: Check-in UX Enhancement
Make the check-in screen scrollable with SingleChildScrollView. Add tag selection chips UI (tags field exists in backend model but has no UI). Add haptic feedback on mood emoji selection. Show a success animation (Lottie or built-in) after check-in instead of plain text. Add pull-to-refresh on the check-in history.

## REQ-4: Mood Heatmap & Charts
Implement a mood calendar heatmap view using the existing `/checkins/heatmap` API endpoint. Add mood trend line charts and energy distribution pie chart to the Insight screen using the `fl_chart` package (already in pubspec.yaml but unused). Display stats from the existing `/checkins/stats` endpoint.

## REQ-5: Insight & Coach Screens
Add an insight history list screen using the existing `/insights/history` API. Add period selector (7d/30d/60d/90d) for generating insights. Create a dedicated Coach/Notifications screen showing all Silent Coach alerts from the `/notifications` API with read/unread state and mark-as-read functionality.

## REQ-6: Backend Input Validation & Security
Add Zod schema validation to all backend route handlers (auth, checkins, insights, goals, coach, notifications). Add admin role field to User model and create adminMiddleware that checks `userRole === 'admin'` before allowing access to `/dashboard/*` routes. Fix password_hash field to use `select: false` in the Mongoose schema.

## REQ-7: Backend Scheduled Jobs & Push Notifications
Implement a node-cron scheduler for: (a) daily check-in reminder push at user's configured `reminder_time`, (b) weekly auto-generation of 7-day insights every Monday. Add Firebase Cloud Messaging integration to send push notifications for reminders, coach alerts, and weekly insight availability.

## REQ-8: AI Sentiment Analysis Upgrade
Replace the current mood_score-only sentiment analysis with sentence-transformers (`paraphrase-multilingual-MiniLM-L12-v2`) that analyzes `text_note` content. Use cosine similarity against Vietnamese sentiment anchor phrases. Combine text sentiment (60% weight when confident) with mood-based sentiment (40% weight). Implement model singleton with lazy loading.

## REQ-9: AI Topic Clustering Upgrade
Replace hardcoded keyword matching with embedding-based topic clustering using sentence-transformers + scikit-learn KMeans. Auto-determine optimal cluster count (k=2-5) via silhouette score. Label clusters by cosine similarity to Vietnamese topic anchor embeddings. Fall back to keyword matching when fewer than 3 text notes exist.

## REQ-10: AI Insight Generation with Ollama LLM
Integrate Ollama (local, free) LLM (llama3.1:8b) for generating personalized insight bullets in Vietnamese. Build structured prompts with check-in metrics context. Parse JSON array response from LLM. Implement 10-second timeout with automatic fallback to the existing rule-based generator. Add async endpoint support.

## REQ-11: AI Statistical Pattern Detection
Upgrade pattern detection with scipy/numpy statistical methods: linear regression for mood trend slope, rolling standard deviation for volatility detection, moving average crossover for downtrend signals, Pearson correlation for energy-mood linkage. Keep existing simple patterns (stress_spike, burnout_risk, missed_checkins) as baseline.

## REQ-12: AI Performance & Caching
Implement model singleton pattern (lazy load once, reuse). Use batch encoding for multiple texts. Add Redis caching for text embeddings (TTL 24h). Add `/ai/health` endpoint reporting model load status and Ollama availability. Update requirements.txt with scipy and torch (CPU).

## REQ-13: Admin Dashboard Charts & Management
Add Chart.js line charts to the Angular admin dashboard showing daily signups and check-ins over 30 days using the existing `/dashboard/chart` API. Add date range filter to check-ins page. Add admin role guard on all dashboard routes. Add top streaks leaderboard view.

## REQ-14: Subscription & Monetization
Add RevenueCat integration in Flutter for subscription management (free/premium plans). Implement feature gating middleware in backend that checks user plan before allowing access to premium features (30/60/90d insights, unlimited goals, coach advanced, PDF report). Add subscription status sync between RevenueCat and the User model's plan field.

## REQ-15: App Store Readiness
Add native splash screen. Implement offline check-in support with local SQLite cache that syncs when online. Add proper i18n localization (Vietnamese + English) using intl package. Add Semantics widgets for accessibility. Implement smart in-app rating prompt triggered after 7-day streak or goal completion. Create privacy policy page.
