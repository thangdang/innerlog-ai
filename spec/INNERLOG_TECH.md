
# INNERLOG – AI Personal Growth Tracker (VN-first)


## 3. SYSTEM ARCHITECTURE

Flutter App
   |
REST API
   |
ExpressJS Backend
   |
HTTP
   |
Python AI Service
   |
MongoDB

---

## 4. MOBILE APP (FLUTTER)

### 4.1 Tech Stack
- Flutter 3.x
- Dart
- Material / Cupertino
- Riverpod hoặc Bloc
- Deploy Android + iOS

---

### 4.2 App Structure

lib/
- core/
- auth/
- checkin/
- insight/
- goal/
- profile/
- shared/

---

### 4.3 Main Screens
- Login / Register
- Daily Check-in
- Weekly Insight
- Goal Tracking
- Profile / Settings

---

## 5. BACKEND (EXPRESSJS)

### 5.1 Tech Stack
- NodeJS 20+
- ExpressJS
- JWT Auth
- MongoDB + Mongoose

---

### 5.2 API Endpoints

Auth:
- POST /api/auth/register
- POST /api/auth/login
- GET  /api/auth/me

Check-in:
- POST /api/checkins
- GET  /api/checkins?from=&to=

Insight:
- POST /api/insight/generate
- GET  /api/insight/latest
- GET  /api/insight/history

Goal:
- POST /api/goals
- GET  /api/goals
- PUT  /api/goals/:id

---

### 5.3 Backend Responsibilities
- Authentication
- CRUD check-in
- Gọi AI service
- Lưu insight
- Subscription / entitlement

---

## 6. DATABASE (MONGODB)

### 6.1 users
{
  _id,
  email,
  password_hash,
  created_at
}

### 6.2 checkins
{
  _id,
  user_id,
  mood_score,
  text_note,
  energy_level,
  created_at
}

Index: user_id + created_at

### 6.3 insights
{
  _id,
  user_id,
  period,
  bullets,
  meta,
  created_at
}

---

## 7. AI SERVICE (PYTHON – FREE)

### 7.1 Tech Stack
- Python 3.11
- FastAPI
- LLaMA 3.1 8B hoặc Mixtral 8x7B (self-host)
- sentence-transformers
- scikit-learn

---

### 7.2 AI Pipeline
Input check-ins
→ Preprocess
→ Sentiment analysis
→ Topic clustering
→ Pattern detection
→ Insight generator

---

### 7.3 Insight Rules
- Rule-based + LLM summary
- Bullet only
- Hard limit length

---

### 7.4 AI API

POST /ai/analyze

Request:
{
  checkins: [...]
}

Response:
{
  bullets: [...],
  metrics: {...}
}

---

## 8. MONETIZATION (MMO)

Free:
- Daily check-in
- Weekly insight cơ bản

Paid (49k–99k/tháng):
- Insight nâng cao
- Goal coach
- PDF report

One-time packs:
- Reset tinh thần 21 ngày
- Focus mùa thi

---

## 9. SECURITY & PRIVACY
- JWT + refresh token
- Không bán dữ liệu
- AI chạy local

---

## 10. 30-DAY SOLO BUILD PLAN

Week 1:
- Auth
- Check-in CRUD
- Flutter UI basic

Week 2:
- AI service v1
- Insight generation

Week 3:
- UX polish
- Silent coach logic

Week 4:
- Paid features
- Beta release

---

END.
