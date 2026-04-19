# 🧠 InnerLog AI — Personal Growth Tracker

> AI-powered personal growth tracker for Vietnamese youth. Theo dõi sức khỏe tinh thần, AI phân tích hành vi và đưa ra insight thông minh.

## Architecture

```
innerlog-mobile (Flutter)  →  innerlog-service (Express.js)  →  innerlog-ai-engine (FastAPI)
                                       ↓                                ↓
                                    MongoDB                     Ollama (LLaMA 3.1 8B)
                                       ↑                        sentence-transformers
innerlog-ui (Angular Admin) →  innerlog-service                  scikit-learn
                                       ↑
                                     Redis
```

## Project Structure

| Folder | Stack | Description |
|--------|-------|-------------|
| `innerlog-service/` | Express.js + TypeScript + Mongoose | Backend API (JWT auth, rate limit) |
| `innerlog-ai-engine/` | Python 3.11 + FastAPI + Ollama | AI insight engine (sentiment, clustering, patterns) |
| `innerlog-ui/` | Angular 21 + ArchitectUI + Bootstrap 5 | Admin dashboard |
| `innerlog-mobile/` | Flutter 3.x + Riverpod | Mobile app (Android + iOS) |
| `docs/` | Markdown | Architecture, flows, setup, deploy guides |
| `spec/` | Markdown | Product specs |

## Features

- 📝 Daily mood check-ins (1–5 scale, energy, notes, tags)
- 🤖 AI insight generation (7d / 30d / 60d / 90d analysis)
- 🔍 Silent Coach — pattern detection (mood drops, stress spikes, burnout risk, missed days)
- 🎯 Goal tracking with micro-tasks + auto-progress
- 🔥 Streak tracking (current + longest)
- 📊 Admin dashboard (users, streaks, chart data)
- 🔔 Coach alerts & reminders
- 🔒 GDPR-compliant — AI runs on local PC, no cloud LLM

## Quick Start

```bash
# Docker (recommended)
cp .env.example .env
docker-compose up -d

# Mobile
cd innerlog-mobile && flutter pub get && flutter run
```

| Service | URL |
|---------|-----|
| Admin UI | http://localhost:80 |
| Backend API | http://localhost:3000 |
| AI Engine | http://localhost:5000 |
| MongoDB | localhost:27017 |
| Redis | localhost:6379 |

## Manual Start

```bash
# 1. Infrastructure
docker run -d --name innerlog-mongo -p 27017:27017 mongo:7
docker run -d --name innerlog-redis -p 6379:6379 redis:7-alpine

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

| Route | Description |
|-------|-------------|
| `POST /api/v1/auth/register` | Register |
| `POST /api/v1/auth/login` | Login |
| `POST /api/v1/auth/refresh` | Refresh token |
| `POST /api/v1/checkins` | Create check-in |
| `GET /api/v1/checkins` | List check-ins |
| `GET /api/v1/checkins/streak` | Current streak |
| `GET /api/v1/checkins/heatmap` | Heatmap data |
| `POST /api/v1/insights/generate` | Generate AI insight |
| `GET /api/v1/insights/latest` | Latest insight |
| `POST /api/v1/goals` | Create goal |
| `POST /api/v1/coach/check` | Silent Coach pattern detection |
| `GET /api/v1/dashboard` | Admin overview |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x, Riverpod, Dio, go_router |
| Admin | Angular 21, ArchitectUI, Bootstrap 5, Chart.js |
| Backend | Express.js 4.x, TypeScript 5.x, Mongoose 8, JWT |
| AI | FastAPI, Ollama (LLaMA 3.1 8B), scikit-learn, sentence-transformers |
| Database | MongoDB 7, Redis 7 |
| Container | Docker Compose |

## AI Pipeline

```
Check-ins → Sentiment Analysis → Topic Clustering → Pattern Detection → Insight Generator
```

## Documentation

- [01 – Architecture](docs/01-architecture.md)
- [02 – Flow](docs/02-flow.md)
- [03 – Setup Guide](docs/03-setup-guide.md)
- [04 – Deploy Guide](docs/04-deploy.md)
- [05 – Hybrid Network](docs/05-hybrid-network.md)

## Design Principles

- Privacy-first: all AI runs locally with Ollama, no data sent to cloud
- Free-first: $0 AI cost, all open-source tools
- Hybrid deployment: AI engine on local PC, services on VPS ($24/mo)
- Redis cache: insights (6h), coach (1h)
