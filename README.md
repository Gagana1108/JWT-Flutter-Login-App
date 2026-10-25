# Full-Stack Flutter & Dart Frog JWT Authentication Application with RBAC

A full-stack Login, Registration, and **Role-Based Access Control (RBAC)** application built with **Flutter** (Frontend), **Dart Frog** (Backend REST API), and **MySQL 8** (Database).

---

## Architecture Overview

```
+-------------------+        HTTP REST API        +-------------------+        SQL TCP        +-------------------+
|  Flutter Frontend | <-------------------------> | Dart Frog Backend | <-------------------> |  MySQL 8 Database |
| (Mobile/Web/Desk) |   (Bearer JWT Header)       |  (Dart REST API)  |   (Port 3306)         |  (auth_db schema) |
+-------------------+                             +-------------------+                       +-------------------+
```

- **Frontend:** Flutter & Dart with Material Design 3, Provider state management, form validation, live password strength rules, Role-Based Dashboards (`User` & `Admin` Console), loading indicators, and error banners.
- **Backend:** Dart Frog framework handling REST endpoints, CORS headers (supporting `PATCH` preflights), JWT verification middleware, RBAC authorization guards (`401 Unauthorized` & `403 Forbidden`), bcrypt password hashing, and refresh token rotation/revocation.
- **Database:** MySQL 8 storing `users` (with `role` constraints) and `refresh_tokens`.

---

## Directory Structure

```
login_jwt/
├── database/
│   ├── schema.sql                      # Complete MySQL database schema
│   └── migration_add_role.sql          # Safe migration script to add RBAC to existing DB
├── backend/
│   ├── .env.example                    # Sample environment variables configuration
│   ├── .env                            # Local development environment secrets
│   ├── pubspec.yaml                    # Dart Frog backend dependencies
│   ├── routes/
│   │   ├── _middleware.dart            # Global middleware (CORS with PATCH support & Service injection)
│   │   └── api/
│   │       └── v1/
│   │           ├── auth/
│   │           │   ├── register.dart   # POST /api/v1/auth/register (Forces 'user' role)
│   │           │   ├── login.dart      # POST /api/v1/auth/login
│   │           │   ├── refresh.dart    # POST /api/v1/auth/refresh (Token Rotation)
│   │           │   └── logout.dart     # POST /api/v1/auth/logout
│   │           ├── user/
│   │           │   ├── _middleware.dart # Protected route JWT Bearer auth guard
│   │           │   └── profile.dart    # GET /profile & PATCH /profile (Update own name)
│   │           └── admin/
│   │               ├── _middleware.dart # Admin authorization guard (Enforces 403 Forbidden)
│   │               └── users/
│   │                   ├── index.dart  # GET /api/v1/admin/users (Admin only)
│   │                   └── [id]/
│   │                       └── role.dart # PATCH /api/v1/admin/users/:id/role (Admin only)
│   └── lib/
│       └── src/
│           ├── config/env.dart          # Env config reader
│           ├── db/mysql_client.dart     # MySQL connection manager
│           ├── models/                  # User (with role), RefreshToken & Auth Response models
│           ├── services/                # UserRepository, TokenRepository, AuthService
│           └── utils/                   # Validators & JsonResponse helpers
└── lib/
    ├── config/api_config.dart          # Platform-aware base URL & endpoint configuration
    ├── models/                         # UserModel (with role & isAdmin) & AuthTokensModel
    ├── providers/auth_provider.dart    # Provider state management & admin actions
    ├── screens/
    │   ├── splash_screen.dart          # Auto-auth token check launcher
    │   ├── login_screen.dart           # Sign-in UI
    │   ├── register_screen.dart        # Sign-up UI with live password meter
    │   ├── profile_screen.dart         # User/Admin Dashboard & profile editor
    │   └── admin_dashboard_screen.dart # Admin Console UI for managing users & roles
    ├── services/
    │   ├── api_service.dart            # HTTP client (GET, POST, PATCH with auto token refresh)
    │   └── storage_service.dart        # Session persistence
    ├── widgets/                        # CustomTextField, CustomButton, MessageBanner
    └── main.dart                       # Flutter app entry point
```

---

## Quick Setup & Execution Instructions on Windows 11

### Step 1: Database Setup (MySQL 8)

1. **For New Database:** Execute `database/schema.sql`:
   ```sql
   mysql -u root -p < database/schema.sql
   ```

2. **For Existing Database Migration:** Execute `database/migration_add_role.sql`:
   ```sql
   mysql -u root -p auth_db < database/migration_add_role.sql
   ```

3. **Seeding Initial Administrator:** Public registration endpoint automatically assigns the `'user'` role to prevent privilege escalation. To set up your initial Administrator account, register a user account normally and elevate its role via SQL:
   ```sql
   USE auth_db;
   UPDATE users SET role = 'admin' WHERE email = 'admin@example.com';
   ```

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

3. Install backend dependencies:
```powershell
dart pub get
```

4. Start the Dart Frog backend server:
```powershell
dart pub global run dart_frog_cli:dart_frog dev
```
*(The backend server will start on `http://localhost:8080`)*

> **Important:** Whenever new backend route files are added, restart the `dart_frog dev` process so Dart Frog can generate route bindings.

---

### Step 3: Run the Flutter Frontend

1. Open a new terminal window in the root project directory:
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
| `POST` | `/api/v1/auth/register` | Public | Register new user (forces default `user` role) |
| `POST` | `/api/v1/auth/login` | Public | Authenticate user & return Access + Refresh JWTs with role payload |
| `POST` | `/api/v1/auth/refresh` | Public | Rotate refresh token & issue new token pair |
| `POST` | `/api/v1/auth/logout` | Public | Revoke user refresh token |
| `GET` | `/api/v1/user/profile` | Bearer JWT | Fetch authenticated user profile |
| `PATCH` | `/api/v1/user/profile` | Bearer JWT | Update user's own profile name |
| `GET` | `/api/v1/admin/users` | Admin JWT | List all registered users (Admin only) |
| `PATCH` | `/api/v1/admin/users/:id/role` | Admin JWT | Update user role (`admin` or `user`) with self-demotion protection |

---

## Security & RBAC Enforcement Features

1. **Role Constraint Integrity**: `users` table enforces `CHECK (role IN ('admin', 'user'))` at the database level.
2. **Public Registration Guard**: Registration endpoint (`POST /api/v1/auth/register`) strictly sets `'user'` role, ignoring any `role` parameters passed in request bodies.
3. **Hybrid JWT + DB Verification**: JWT access tokens carry `'role'` claims for fast inspection, while the Admin Middleware (`backend/routes/api/v1/admin/_middleware.dart`) re-verifies active user permissions against the database to prevent stale access token privilege bypasses.
4. **Self-Demotion Protection**: Administrators cannot revoke their own admin privileges via API to prevent lockouts.
5. **CORS Compliance**: Backend configured with full preflight handling including `PATCH` method support.
