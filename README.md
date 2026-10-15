# ⚖️ JusticeNow

> Human rights case tracking and management platform — bridging citizens, investigators, NGOs, and legal practitioners.

---

## 📋 Overview

JusticeNow enables citizens to safely report human rights violations, track case progress, and connect with verified legal aid organizations — all with privacy-first design.

### Core Modules
| Module | Description |
|---|---|
| **Case Reporting** | Anonymous or registered incident reports with multimedia evidence |
| **Case Tracking** | Live milestone tracking, timeline logs, and investigator feedback |
| **Legal Aid** | Verified NGO and legal practitioner directory |
| **Analytics Dashboard** | Case statistics, hotspot mapping, and trend analysis for officers |

---

## 🏗️ Architecture

```
JusticeNow/
├── backend/        # Node.js + Express.js MVC REST API
└── mobile/         # Flutter iOS + Android app
```

---

## 🚀 Getting Started

### Prerequisites
- **Node.js** v18+
- **MongoDB** v6+ (local or Atlas)
- **Flutter** SDK 3.x
- **Firebase** project (for NGO/Officer auth)

---

### 🖥️ Backend

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Set up environment
cp .env.example .env
# Edit .env with your MongoDB URI, JWT secret, and Firebase credentials

# 3. Start development server
npm run dev
# → Server running at http://localhost:3000
# → Health check: http://localhost:3000/api/health
```

#### API Endpoints

| Method | Endpoint | Description | Auth |
|---|---|---|---|
| `POST` | `/api/auth/anonymous` | Create anonymous session | None |
| `POST` | `/api/auth/register` | Register citizen | None |
| `POST` | `/api/auth/login` | Citizen login | None |
| `POST` | `/api/auth/firebase` | Firebase staff login | None |
| `GET` | `/api/auth/me` | Get current user | JWT |
| `POST` | `/api/cases` | Submit case report | JWT |
| `GET` | `/api/cases` | List all cases | Officer/Admin |
| `GET` | `/api/cases/my` | My cases | JWT |
| `GET` | `/api/cases/:id` | Case detail | Owner/Staff |
| `PATCH` | `/api/cases/:id/status` | Update case status | Officer/Admin |
| `POST` | `/api/cases/:id/evidence` | Upload evidence | JWT |
| `GET` | `/api/legal-aid/organizations` | List organizations | Public |
| `GET` | `/api/analytics/summary` | Dashboard stats | Officer/Admin |
| `GET` | `/api/analytics/hotspots` | Geo hotspot data | Officer/Admin |
| `GET` | `/api/analytics/trends` | 12-month trends | Officer/Admin |

---

### 📱 Mobile (Flutter)

> **⚠️ Note**: Flutter is not currently installed on this machine.  
> Install Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/macos) then:

```bash
cd mobile

# 1. Initialize Flutter project
flutter create . --org com.justicenow

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase
# - Add google-services.json to android/app/
# - Add GoogleService-Info.plist to ios/Runner/
# - Run: flutterfire configure

# 4. Run on device/emulator
flutter run
```

#### Project Structure
```
mobile/lib/
├── core/
│   ├── constants/      # App-wide constants (API base URL, status labels)
│   ├── router/         # GoRouter navigation
│   ├── theme/          # Design system (colors, typography, components)
│   └── utils/          # Helper utilities
├── data/
│   ├── repositories/   # API data layer (auth, cases)
│   └── services/       # Dio API service with auto-auth injection
├── presentation/
│   ├── screens/        # Full screens (auth, cases, legal aid, dashboard)
│   └── widgets/        # Shared widgets
└── providers/          # Riverpod state providers
```

---

## 🔐 Auth Architecture

```
Anonymous Citizen    → POST /auth/anonymous → JWT token (30 days)
Registered Citizen   → POST /auth/login     → JWT token (30 days)
NGO/Officer/Admin    → Firebase Sign-In → POST /auth/firebase → JWT token
```

All protected routes accept: `Authorization: Bearer <token>`

---

## 🗄️ Database Collections

| Collection | Purpose |
|---|---|
| `users` | All user types (anonymous, citizen, staff) |
| `cases` | Incident reports with full lifecycle |
| `evidences` | Files with chain-of-custody log |
| `organizations` | Verified NGOs and legal firms |
| `auditlogs` | Immutable action log (5-year retention) |

---

## 🛡️ Security Features

- `helmet` — HTTP security headers
- `cors` — Configurable origin allowlist
- `express-rate-limit` — 100 req/15min global limit
- SHA-256 integrity hash on all evidence files
- Chain-of-custody log for every evidence access
- JWT stored in `flutter_secure_storage` (iOS Keychain / Android Keystore)
- Passwords hashed with `bcryptjs` (12 rounds)

---

## 📄 License

MIT License — see [LICENSE](./LICENSE)
