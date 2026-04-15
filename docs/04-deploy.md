# InnerLog AI – Deploy Guide

## Mục lục
1. [Deploy lên VPS (Ubuntu)](#1-deploy-lên-vps-ubuntu)
2. [Deploy Mobile lên App Store / Google Play](#2-deploy-mobile)
3. [CI/CD Pipeline](#3-cicd-pipeline)
4. [Monitoring & Maintenance](#4-monitoring)
5. [Chi phí Deploy (Cost Estimation)](#5-chi-phí-deploy-cost-estimation)

> Xem thêm: [Hybrid Network Diagram](./05-hybrid-network.md)

---

## 1. Deploy lên VPS (Ubuntu)

### Yêu cầu VPS

| Spec | Minimum | Recommended |
|------|---------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4 GB | 8 GB |
| Disk | 40 GB SSD | 80 GB SSD |
| OS | Ubuntu 22.04+ | Ubuntu 24.04 |
| Provider | DigitalOcean, Vultr, Linode, AWS Lightsail | Bất kỳ |

> Chi phí ước tính: $12-24/tháng (DigitalOcean/Vultr)

### Bước 1: Chuẩn bị VPS

```bash
# SSH vào VPS
ssh root@your-vps-ip

# Update system
apt update && apt upgrade -y

# Cài Docker + Docker Compose
curl -fsSL https://get.docker.com | sh
apt install docker-compose-plugin -y

# Cài Nginx (reverse proxy)
apt install nginx certbot python3-certbot-nginx -y

# Tạo user deploy
adduser deploy
usermod -aG docker deploy
su - deploy
```

### Bước 2: Clone project

```bash
cd /home/deploy
git clone <your-repo-url> innerlog-ai
cd innerlog-ai
```

### Bước 3: Cấu hình production .env

```bash
cp .env.example .env
nano .env
```

```env
PORT=3000
NODE_ENV=production
MONGODB_URI=mongodb://mongodb:27017/innerlog_ai
REDIS_URL=redis://redis:6379
AI_SERVICE_URL=http://innerlog-ai-engine:5000

# QUAN TRỌNG: Đổi secret keys!
JWT_SECRET=generate-random-64-char-string-here
JWT_REFRESH_SECRET=generate-another-random-64-char-string-here
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d
```

Tạo secret key:
```bash
openssl rand -hex 32
```

### Bước 4: Build & chạy Docker

```bash
docker compose up -d --build
```

Verify:
```bash
docker compose ps
curl http://localhost:3000/health
curl http://localhost:5000/health
```

### Bước 5: Cấu hình Nginx (Reverse Proxy + SSL)

```bash
nano /etc/nginx/sites-available/innerlog
```

```nginx
# API Backend
server {
    listen 80;
    server_name api.innerlog.vn;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Admin Dashboard
server {
    listen 80;
    server_name admin.innerlog.vn;

    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/innerlog /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### Bước 6: SSL Certificate (Let's Encrypt — Free)

```bash
certbot --nginx -d api.innerlog.vn -d admin.innerlog.vn
# Tự động renew
certbot renew --dry-run
```

### Bước 7: Firewall

```bash
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS
ufw enable
```

### Bước 8: MongoDB Backup (Cron)

```bash
mkdir -p /home/deploy/backups

# Tạo backup script
cat > /home/deploy/backup-mongo.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M)
docker exec $(docker ps -qf "ancestor=mongo:7") mongodump --out /dump
docker cp $(docker ps -qf "ancestor=mongo:7"):/dump /home/deploy/backups/mongo_$DATE
# Xóa backup cũ hơn 30 ngày
find /home/deploy/backups -type d -mtime +30 -exec rm -rf {} +
EOF

chmod +x /home/deploy/backup-mongo.sh

# Cron: backup mỗi ngày lúc 3:00 AM
crontab -e
# Thêm dòng:
# 0 3 * * * /home/deploy/backup-mongo.sh
```

### Update / Redeploy

```bash
cd /home/deploy/innerlog-ai
git pull
docker compose up -d --build
```

---

## 2. Deploy Mobile

### 2.1 Android — Google Play Store

#### Bước 1: Đổi API URL cho production

```dart
// lib/core/api.dart
static const String baseUrl = 'https://api.innerlog.vn/api/v1';
```

#### Bước 2: Tạo keystore

```bash
cd innerlog-mobile
keytool -genkey -v -keystore ~/innerlog-upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias innerlog
```

#### Bước 3: Cấu hình signing

Tạo file `android/key.properties`:
```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=innerlog
storeFile=/path/to/innerlog-upload-keystore.jks
```

Sửa `android/app/build.gradle`:
```groovy
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

#### Bước 4: Build APK / AAB

```bash
# App Bundle (Google Play yêu cầu)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab

# APK (test trực tiếp)
flutter build apk --release
```

#### Bước 5: Upload Google Play Console

1. Vào https://play.google.com/console
2. Tạo app mới → "InnerLog - Theo dõi cuộc sống"
3. Upload `.aab` file
4. Điền thông tin:
   - Category: Health & Fitness
   - Content rating: Everyone
   - Privacy policy URL (bắt buộc)
5. Submit review → chờ 1-3 ngày

### 2.2 iOS — App Store (Không cần macOS)

> Bạn đang dùng Windows nên không thể build iOS trực tiếp.
> Dưới đây là các cách thay thế:

#### Option A: Codemagic CI/CD (Recommended — Free tier)

Codemagic cung cấp macOS build machines trên cloud, build Flutter iOS mà không cần Mac.

##### A1. Tạo Apple Developer Account (bắt buộc cho iOS)

> Đây là tài khoản Apple, KHÔNG phải Codemagic. Bạn cần nó để publish app lên App Store.

1. Vào https://developer.apple.com/programs/enroll/
2. Đăng nhập bằng Apple ID (tạo mới tại https://appleid.apple.com nếu chưa có)
3. Chọn **"Enroll as Individual"** (cá nhân) hoặc **"Organization"** (công ty)
4. Điền thông tin cá nhân (tên, địa chỉ, CMND/CCCD)
5. Thanh toán **$99/năm** (Visa/Mastercard)
6. Chờ Apple duyệt: **24-48 giờ**
7. Sau khi duyệt → bạn có quyền truy cập:
   - https://developer.apple.com (quản lý certificates, app IDs)
   - https://appstoreconnect.apple.com (quản lý app trên App Store)

##### A2. Tạo App trên App Store Connect

1. Vào https://appstoreconnect.apple.com → **"My Apps"** → **"+"** → **"New App"**
2. Điền:
   - Platform: **iOS**
   - Name: **InnerLog**
   - Primary Language: **Vietnamese**
   - Bundle ID: tạo mới → `vn.innerlog.app`
   - SKU: `innerlog-001`
3. Nhấn **Create**
4. Điền metadata:
   - Subtitle: "Theo dõi cuộc sống thông minh"
   - Category: **Health & Fitness**
   - Privacy Policy URL: `https://innerlog.vn/privacy` (bắt buộc — tạo 1 trang đơn giản)
   - Screenshots: chụp từ emulator (6.7" iPhone, 6.5" iPhone, iPad)
5. **Chưa submit** — chờ Codemagic build xong rồi submit

##### A3. Tạo API Key cho Codemagic (để tự động upload)

1. Vào https://appstoreconnect.apple.com → **"Users and Access"** → tab **"Integrations"** → **"App Store Connect API"**
2. Nhấn **"+"** → tạo key mới:
   - Name: `Codemagic`
   - Access: **App Manager**
3. Download file `.p8` (chỉ download được 1 lần — lưu cẩn thận!)
4. Ghi lại:
   - **Issuer ID** (hiển thị trên trang)
   - **Key ID** (hiển thị bên cạnh key)
   - **File .p8** (vừa download)

##### A4. Đăng ký Codemagic + kết nối

1. Vào https://codemagic.io → **"Sign up"** (đăng ký bằng GitHub/GitLab/Bitbucket)
2. Nhấn **"Add application"** → chọn repo `innerlog-ai`
3. Chọn **"Flutter App"**
4. Vào **Settings** → **"Code signing — iOS"**:
   - Chọn **"Automatic"** (Codemagic tự quản lý certificates)
   - Nhập **Issuer ID**, **Key ID**, upload file **.p8** (từ bước A3)
   - Bundle Identifier: `vn.innerlog.app`
5. Vào **Settings** → **"Publishing"** → **"App Store Connect"**:
   - Enable → nhập lại Issuer ID + Key ID + .p8

##### A5. Tạo codemagic.yaml

Tạo file `innerlog-mobile/codemagic.yaml`:

```yaml
workflows:
  ios-release:
    name: iOS Release
    max_build_duration: 60
    instance_type: mac_mini_m2
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
      groups:
        - app_store_credentials
    scripts:
      - name: Set up code signing
        script: |
          keychain initialize
          app-store-connect fetch-signing-files "vn.innerlog.app" \
            --type IOS_APP_STORE \
            --create
          keychain add-certificates
          xcode-project use-profiles
      - name: Flutter pub get
        script: flutter pub get
      - name: Build IPA
        script: |
          flutter build ipa --release \
            --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      app_store_connect:
        auth: integration
        submit_to_testflight: true
        submit_to_app_store: false

  android-release:
    name: Android Release
    max_build_duration: 30
    instance_type: linux_x2
    environment:
      flutter: stable
      java: 17
    scripts:
      - name: Build AAB
        script: |
          flutter pub get
          flutter build appbundle --release
    artifacts:
      - build/app/outputs/bundle/release/*.aab
```

##### A6. Build & Publish

1. Commit + push `codemagic.yaml` lên repo
2. Vào Codemagic dashboard → nhấn **"Start new build"** → chọn workflow **"iOS Release"**
3. Codemagic sẽ:
   - Tự tạo certificates + provisioning profiles
   - Build Flutter iOS trên macOS cloud
   - Upload `.ipa` lên **TestFlight** (App Store Connect)
4. Vào App Store Connect → **"TestFlight"** → thấy build mới
5. Test trên TestFlight → OK → vào **"App Store"** tab → chọn build → **"Submit for Review"**
6. Apple review: **1-7 ngày** → app lên App Store!

##### Tổng chi phí iOS:

| Mục | Chi phí |
|-----|---------|
| Apple Developer Account | $99/năm |
| Codemagic Free tier | $0 (500 build minutes/tháng) |
| **Tổng** | **$99/năm** |

#### Option B: GitHub Actions + macOS Runner

```yaml
# .github/workflows/ios-build.yml
name: iOS Build
on:
  push:
    branches: [main]
jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: cd innerlog-mobile && flutter pub get
      - run: cd innerlog-mobile && flutter build ipa --release --no-codesign
      - uses: actions/upload-artifact@v4
        with:
          name: ios-build
          path: innerlog-mobile/build/ios/ipa/
```

> GitHub Actions cung cấp macOS runners miễn phí (2000 minutes/tháng cho public repos).

#### Option C: Thuê Mac cloud

- https://www.macincloud.com (~$20/tháng)
- https://www.macstadium.com
- Remote desktop vào Mac → build bình thường

#### Yêu cầu chung cho iOS:

- Apple Developer Account ($99/năm) — bắt buộc
- Bundle Identifier: `vn.innerlog.app`
- Privacy policy URL (bắt buộc)
- App Store Connect: điền metadata, screenshots
- Review time: 1-7 ngày

---

## 3. CI/CD Pipeline

### GitHub Actions (ví dụ)

Tạo `.github/workflows/deploy.yml`:

```yaml
name: Deploy InnerLog

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to VPS
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: deploy
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /home/deploy/innerlog-ai
            git pull origin main
            docker compose up -d --build
```

---

## 4. Monitoring

### Health Checks

```bash
# Cron: check mỗi 5 phút
*/5 * * * * curl -sf http://localhost:3000/health || echo "innerlog-service DOWN" | mail -s "Alert" admin@innerlog.vn
*/5 * * * * curl -sf http://localhost:5000/health || echo "innerlog-ai-engine DOWN" | mail -s "Alert" admin@innerlog.vn
```

### Docker Logs

```bash
# Xem logs
docker compose logs -f innerlog-service
docker compose logs -f innerlog-ai-engine

# Xem logs 100 dòng gần nhất
docker compose logs --tail=100 innerlog-service
```

### Disk / Memory

```bash
# Check disk
df -h

# Check memory
free -h

# Check Docker resource usage
docker stats
```

---

## 5. Chi phí Deploy (Cost Estimation)

### 5.1 Tổng quan hạ tầng

InnerLog AI gồm 5 containers: innerlog-service (Express.js), innerlog-ai-engine (FastAPI + scikit-learn + sentence-transformers + Ollama), innerlog-ui (Angular + Nginx), MongoDB 7, Redis 7. AI chạy local hoàn toàn — không tốn phí API.

### 5.2 Option A — VPS đơn giản (MVP, < 1,000 users)

| Hạng mục | Dịch vụ | Chi phí/tháng |
|----------|---------|---------------|
| VPS (4 vCPU, 8GB RAM, 80GB SSD) | DigitalOcean / Vultr / Linode | $48 (~1,200,000đ) |
| Domain `.vn` | VNNIC | ~30,000đ/tháng |
| SSL Certificate | Let's Encrypt | **Miễn phí** |
| Ollama LLM (LLaMA 3.1 8B) | Chạy local trên VPS | **Miễn phí** |
| sentence-transformers | Chạy local trên VPS | **Miễn phí** |
| MongoDB 7 + Redis 7 | Docker trên VPS | **Miễn phí** |
| Docker Hub (public repo) | Docker Hub Free | **Miễn phí** |
| GitHub Actions CI/CD | GitHub Free (2,000 min/tháng) | **Miễn phí** |
| **Tổng Option A** | | **~$50/tháng (~1,250,000đ)** |

> VPS 2 vCPU / 4GB ($24/tháng) cũng chạy được nhưng Ollama + sentence-transformers sẽ chậm. Nên bật swap 4GB.

### 5.3 Option B — Hybrid: Local PC (AI) + VPS $24 ⭐ RECOMMENDED

Chạy AI engine trên máy cá nhân (Windows 11, 16GB RAM), phần còn lại trên VPS rẻ. Khi PC offline, insight/coach có local fallback (basic analysis).

**Phân chia workload:**

| Chạy ở đâu | Services | RAM cần |
|-------------|----------|---------|
| **Local PC** (Win 11, 16GB) | innerlog-ai-engine (sentiment + clustering + Ollama insight) | ~5–6 GB |
| **VPS $24** (2 vCPU, 4GB) | innerlog-service + innerlog-ui + MongoDB + Redis | ~2–2.5 GB |

**Chi phí:**

| Hạng mục | Dịch vụ | Chi phí/tháng |
|----------|---------|---------------|
| VPS (2 vCPU, 4GB RAM, 80GB SSD) | DigitalOcean Basic | **$24 (~600,000đ)** |
| Domain `.vn` | VNNIC | ~30,000đ/tháng |
| SSL | Let's Encrypt | **Miễn phí** |
| Ollama + sentence-transformers + scikit-learn | Chạy trên PC | **Miễn phí** |
| **Tổng Option B** | | **~$26/tháng (~650,000đ)** |

**Graceful degradation khi PC offline:**

| Endpoint | Khi PC online | Khi PC offline (fallback) |
|----------|---------------|---------------------------|
| `POST /insights/generate` | Full AI: sentiment + clustering + Ollama insight | Basic: avg mood + trend label + "AI offline" disclaimer |
| `POST /coach/check` | Full: 5 pattern detectors (mood drop, stress, energy, missed, burnout) | Basic: mood drop + stress spike detection (local JS) |
| Check-in CRUD | ✅ Luôn hoạt động | ✅ Luôn hoạt động |
| Goals CRUD | ✅ Luôn hoạt động | ✅ Luôn hoạt động |
| Streak tracking | ✅ Luôn hoạt động | ✅ Luôn hoạt động |

> InnerLog AI không cần real-time AI response — insights được generate theo yêu cầu (weekly), coach check chạy background. Fallback local đủ tốt cho MVP.

**Code đã implement:**
- `insights.ts` — try/catch với local fallback: tính avg mood + trend + basic bullets
- `coach.ts` — try/catch với local fallback: mood drop + stress spike detection bằng JS
- Không cần Groq/Gemini fallback vì AI engine chủ yếu rule-based (không phụ thuộc LLM nặng)

### 5.4 Option C — VPS nâng cao (1,000–10,000 users)

| Hạng mục | Dịch vụ | Chi phí/tháng |
|----------|---------|---------------|
| VPS chính (8 vCPU, 16GB RAM, 160GB SSD) | DigitalOcean Premium | $96 (~2,400,000đ) |
| Managed MongoDB (tùy chọn) | MongoDB Atlas M10 | $57 (~1,425,000đ) |
| Backup storage (S3-compatible) | DigitalOcean Spaces 250GB | $5 (~125,000đ) |
| Domain + SSL | VNNIC + Let's Encrypt | ~30,000đ/tháng |
| **Tổng Option B** | | **~$100–$160/tháng (~2,500,000–4,000,000đ)** |

### 5.4 Chi phí Mobile App

| Hạng mục | Chi phí | Ghi chú |
|----------|---------|---------|
| Google Play Developer | $25 (một lần) | Lifetime |
| Apple Developer Program | $99/năm | Bắt buộc cho iOS |
| Codemagic CI/CD (build iOS) | **Miễn phí** | Free tier: 500 min/tháng |
| **Tổng Mobile/năm** | **~$124 năm đầu, $99/năm sau** | |

### 5.5 Tổng hợp so sánh

| | Option A (All VPS) | Option B (Hybrid) ⭐ | Option C (Growth) |
|---|---|---|---|
| Users | < 1,000 | < 1,000 | 1,000–10,000 |
| Chi phí/tháng | ~$50 | **~$26** | ~$100–$160 |
| VPS cần | 8GB RAM | **4GB RAM ($24)** | 16GB RAM |
| AI quality | Full | Full (basic fallback khi PC tắt) | Full |
| GDPR (data local) | ✅ | ✅ (AI trên PC, không gửi ra ngoài) | ✅ |
| 24/7 AI | ✅ | ⚠️ Basic fallback | ✅ |

> Điểm mạnh: toàn bộ AI stack (Ollama + scikit-learn + sentence-transformers) chạy local, **$0 chi phí API**. Dữ liệu sức khỏe tinh thần không gửi ra bên ngoài — phù hợp GDPR.

---

## Checklist Deploy Production

- [ ] Đổi JWT_SECRET + JWT_REFRESH_SECRET (random 64 chars)
- [ ] NODE_ENV=production
- [ ] SSL certificate (Let's Encrypt)
- [ ] Firewall (chỉ mở 22, 80, 443)
- [ ] MongoDB backup cron
- [ ] Đổi API URL trong mobile app
- [ ] Tạo keystore cho Android
- [ ] Apple Developer account cho iOS
- [ ] Privacy policy page
- [ ] Health check monitoring
- [ ] Domain DNS trỏ về VPS IP
