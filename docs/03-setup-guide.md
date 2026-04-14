# InnerLog AI – Setup Guide

## Yêu cầu hệ thống

| Tool | Version | Mục đích |
|------|---------|----------|
| Node.js | 20+ | Backend + Admin UI |
| npm | 10+ | Package manager |
| Python | 3.11+ | AI Engine |
| pip | 23+ | Python packages |
| MongoDB | 7+ | Database |
| Redis | 7+ | Cache |
| Flutter | 3.x | Mobile app |
| Docker | 24+ | Container (optional) |
| Git | 2.x | Version control |

---

## Cách 1: Docker (Nhanh nhất)

### Bước 1: Clone & config

```bash
cd innerlog-ai
cp .env.example .env
# Chỉnh sửa .env nếu cần (JWT_SECRET, ...)
```

### Bước 2: Chạy tất cả

```bash
docker-compose up -d
```

Kết quả:
- Backend API: http://localhost:3000
- Admin UI: http://localhost:80
- AI Engine: http://localhost:5000
- MongoDB: localhost:27017
- Redis: localhost:6379

### Bước 3: Mobile app (chạy riêng)

```bash
cd innerlog-mobile
flutter pub get
flutter run
```

---

## Cách 2: Chạy từng service (Development)

### Bước 1: Chuẩn bị

```bash
cd innerlog-ai
cp .env.example .env
```

### Bước 2: MongoDB + Redis

```bash
# Option A: Docker chỉ cho DB
docker run -d --name innerlog-mongo -p 27017:27017 mongo:7
docker run -d --name innerlog-redis -p 6379:6379 redis:7-alpine

# Option B: Cài local
# MongoDB: https://www.mongodb.com/docs/manual/installation/
# Redis: https://redis.io/docs/install/
```

### Bước 3: Backend (innerlog-service)

```bash
cd innerlog-service
npm install
npm run dev
```

Chạy tại: http://localhost:3000
Health check: http://localhost:3000/health

### Bước 4: AI Engine (innerlog-ai-engine)

```bash
cd innerlog-ai-engine
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS/Linux
source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --port 5000 --reload
```

Chạy tại: http://localhost:5000
Health check: http://localhost:5000/health
API docs: http://localhost:5000/docs (Swagger UI tự động)

### Bước 5: Admin UI (innerlog-ui)

```bash
cd innerlog-ui
npm install
npm start
```

Chạy tại: http://localhost:4200
Proxy tự động forward `/api` → `localhost:3000`

### Bước 6: Mobile App (innerlog-mobile)

```bash
cd innerlog-mobile
flutter pub get

# Android emulator
flutter run

# iOS simulator (macOS only)
flutter run -d ios

# Chạy trên thiết bị thật
flutter run -d <device-id>
```

> Lưu ý: Mobile app kết nối API qua `http://10.0.2.2:3000` (Android emulator).
> Đổi trong `lib/core/api.dart` nếu chạy trên thiết bị thật.

---

## Cấu hình Environment (.env)

```env
# Server
PORT=3000
NODE_ENV=development

# MongoDB
MONGODB_URI=mongodb://localhost:27017/innerlog_ai

# Redis
REDIS_URL=redis://localhost:6379

# AI Service
AI_SERVICE_URL=http://localhost:5000

# JWT — BẮT BUỘC đổi trong production!
JWT_SECRET=your-secret-key-change-in-production
JWT_REFRESH_SECRET=your-refresh-secret-change-in-production
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# Ollama (Optional — cho LLM insight)
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.1:8b
```

---

## Cài Ollama (Optional — AI nâng cao)

Ollama cho phép chạy LLM local, hoàn toàn free.

```bash
# Cài Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Tải model
ollama pull llama3.1:8b

# Verify
ollama run llama3.1:8b "Hello"
```

---

## Test API nhanh

```bash
# Health check
curl http://localhost:3000/health
curl http://localhost:5000/health

# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@innerlog.vn","password":"123456","display_name":"Test User"}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@innerlog.vn","password":"123456"}'

# Check-in (thay TOKEN)
curl -X POST http://localhost:3000/api/v1/checkins \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"mood_score":4,"energy_level":"high","text_note":"Hôm nay vui"}'
```

---

## Troubleshooting

| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| `ECONNREFUSED :27017` | MongoDB chưa chạy | `docker start innerlog-mongo` |
| `ECONNREFUSED :6379` | Redis chưa chạy | `docker start innerlog-redis` |
| `ECONNREFUSED :5000` | AI engine chưa chạy | `cd innerlog-ai-engine && uvicorn app.main:app --port 5000` |
| `Invalid token` | Token hết hạn | Gọi `/auth/refresh` hoặc login lại |
| Flutter `SocketException` | Sai API URL | Đổi `baseUrl` trong `lib/core/api.dart` |
| `ng serve` lỗi | Thiếu dependencies | `cd innerlog-ui && npm install` |
