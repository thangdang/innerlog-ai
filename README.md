# InnerLog AI – Personal Growth Tracker

> AI-powered personal growth tracker for Vietnamese youth.

## Architecture

```
innerlog-mobile (Flutter)  →  innerlog-service (Express.js)  →  innerlog-ai-engine (FastAPI)
                                       ↓
                                    MongoDB
                                       ↑
innerlog-ui (Angular Admin)  →  innerlog-service
```

## Project Structure

| Folder | Stack | Description |
|--------|-------|-------------|
| `innerlog-service/` | Express.js + TypeScript + MongoDB | Backend API |
| `innerlog-ui/` | Angular 21 + ArchitectUI + Bootstrap 5 | Admin dashboard |
| `innerlog-ai-engine/` | Python 3.11 + FastAPI | AI insight engine |
| `innerlog-mobile/` | Flutter 3.x + Riverpod | Mobile app (Android + iOS) |

## Quick Start

```bash
# 1. Start infrastructure
docker-compose up mongodb redis -d

# 2. Backend
cd innerlog-service && npm install && npm run dev

# 3. AI Engine
cd innerlog-ai-engine && pip install -r requirements.txt
uvicorn app.main:app --port 5000 --reload

# 4. Admin UI
cd innerlog-ui && npm install && npm start

# 5. Mobile
cd innerlog-mobile && flutter pub get && flutter run
```

## API Endpoints

- `POST /api/v1/auth/register` — Register
- `POST /api/v1/auth/login` — Login
- `POST /api/v1/checkins` — Create check-in
- `GET  /api/v1/checkins` — List check-ins
- `POST /api/v1/insights/generate` — Generate AI insight
- `GET  /api/v1/insights/latest` — Latest insight
- `POST /api/v1/goals` — Create goal
- `GET  /api/v1/dashboard` — Admin overview
