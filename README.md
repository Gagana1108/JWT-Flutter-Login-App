# Full-Stack Flutter & Dart Frog JWT Authentication Application

A full-stack Login & Registration application built with **Flutter** (Frontend), **Dart Frog** (Backend REST API), and **MySQL 8** (Database).

---

## Architecture Overview

```
+-------------------+        HTTP REST API        +-------------------+        SQL TCP        +-------------------+
|  Flutter Frontend | <-------------------------> | Dart Frog Backend | <-------------------> |  MySQL 8 Database |
| (Mobile/Web/Desk) |   (Bearer JWT Header)       |  (Dart REST API)  |   (Port 3306)         |  (auth_db schema) |
+-------------------+                             +-------------------+                       +-------------------+
```

- **Frontend:** Flutter & Dart with Material Design 3, Provider state management, form validation, real-time password strength rules, password visibility toggles, loading indicators, and error banners.
- **Backend:** Dart Frog framework handling REST endpoints, CORS headers, JWT verification middleware, bcrypt password hashing, and refresh token rotation/revocation.
- **Database:** MySQL 8 storing `users` and `refresh_tokens`.

---

## Directory Structure

```
login_jwt/
├── database/
│   └── schema.sql                  # MySQL database initialization script
├── backend/
│   ├── .env.example                # Sample environment variables configuration
│   ├── .env                        # Local development environment secrets
│   ├── pubspec.yaml                # Dart Frog backend dependencies
│   ├── routes/
│   │   ├── _middleware.dart        # Global middleware (CORS, DB & Service injection)
│   │   └── api/
│   │       └── v1/
│   │           ├── auth/
│   │           │   ├── register.dart # POST /api/v1/auth/register
│   │           │   ├── login.dart    # POST /api/v1/auth/login
│   │           │   ├── refresh.dart  # POST /api/v1/auth/refresh (Rotation)
│   │           │   └── logout.dart   # POST /api/v1/auth/logout
│   │           └── user/
│   │               ├── _middleware.dart # Protected route JWT Bearer auth guard
│   │               └── profile.dart    # GET /api/v1/user/profile
│   └── lib/
│       └── src/
│           ├── config/env.dart          # Env config reader
│           ├── db/mysql_client.dart     # MySQL connection manager
│           ├── models/                  # User, RefreshToken & Auth Response models
│           ├── services/                # UserRepository, TokenRepository, AuthService
│           └── utils/                   # Validators & JsonResponse helpers
└── lib/
    ├── config/api_config.dart      # Platform-aware base URL configuration
    ├── models/                     # UserModel & AuthTokensModel
    ├── providers/auth_provider.dart# ChangeNotifier state provider
    ├── screens/
    │   ├── splash_screen.dart      # Auto-auth token check launcher
    │   ├── login_screen.dart       # Sign-in UI
    │   ├── register_screen.dart    # Sign-up UI with live password meter
    │   └── profile_screen.dart     # User dashboard & session token inspector
    ├── services/
    │   ├── api_service.dart        # HTTP client with auto 401 token refresh retry
    │   └── storage_service.dart    # SharedPreferences session persistence
    ├── widgets/                    # CustomTextField, CustomButton, MessageBanner
    └── main.dart                   # Flutter app entry point
```

---

## Quick Setup & Execution Instructions on Windows 11

### Step 1: Database Setup (MySQL 8)

1. Open MySQL Command Line or MySQL Workbench and execute `database/schema.sql`:

```sql
mysql -u root -p < database/schema.sql
```

This creates the `auth_db` database, `users` table, and `refresh_tokens` table.

---

### Step 2: Configure & Start Dart Frog Backend

1. Navigate to the `backend` folder:
```powershell
cd backend
```

2. Verify `.env` database parameters match your MySQL setup:
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=auth_db
DB_USER=root
DB_PASSWORD=your_mysql_password
JWT_SECRET=super_secret_jwt_key_change_me_in_production_123456789
```

3. Install Dart Frog CLI (if not already installed):
```powershell
dart pub global activate dart_frog_cli
```

4. Install backend dependencies:
```powershell
dart pub get
```

5. Start the Dart Frog backend server:
```powershell
dart pub global run dart_frog_cli:dart_frog dev
```
*(The backend server will start on `http://localhost:8080`)*

---

### Step 3: Run the Flutter Frontend

1. Open a new terminal window in the root `login_jwt` project directory:
```powershell
flutter pub get
```

2. Run Flutter on your preferred device:
   - **Windows Desktop:**
     ```powershell
     flutter run -d windows
     ```
   - **Web Browser (Chrome):**
     ```powershell
     flutter run -d chrome
     ```
   - **Android Emulator:**
     ```powershell
     flutter run -d android
     ```

---

## API Endpoints Summary

| Method | Endpoint | Protection | Description |
|---|---|---|---|
| `POST` | `/api/v1/auth/register` | Public | Register new user with password hashing |
| `POST` | `/api/v1/auth/login` | Public | Authenticate user & return Access + Refresh JWTs |
| `POST` | `/api/v1/auth/refresh` | Public | Rotate refresh token & issue new token pair |
| `POST` | `/api/v1/auth/logout` | Public | Revoke user refresh token |
| `GET` | `/api/v1/user/profile` | Bearer JWT | Fetch authenticated user details |
