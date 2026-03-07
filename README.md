# Neamet - Grocery Delivery App

A full-stack grocery delivery application with a FastAPI backend and Flutter mobile frontend.

## 📁 Project Structure

```
Mini_project/
├── backend/                 # FastAPI backend service
│   ├── app/                # Main application code
│   │   ├── __init__.py
│   │   ├── auth.py         # Authentication logic
│   │   ├── database.py     # Database configuration
│   │   ├── main.py         # FastAPI main application
│   │   ├── models.py       # SQLAlchemy models
│   │   ├── schemas.py      # Pydantic schemas
│   │   └── seed.py         # Database seeding
│   ├── myenv/              # Python virtual environment
│   ├── scripts/            # Helper scripts
│   ├── requirements.txt    # Python dependencies
│   ├── run.py             # Entry point to run the server
│   ├── Procfile           # Deployment configuration
│   ├── render.yaml        # Render deployment specs
│   ├── sql_schema.sql     # Database schema
│   ├── sql_seed.sql       # Sample data
│   ├── .env.example       # Environment variables template
│   └── README.md          # Backend documentation
│
├── frontend/               # Flutter mobile application
│   ├── lib/               # Dart source code
│   │   ├── constants/     # App constants
│   │   ├── models/        # Data models
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API services
│   │   ├── widgets/       # Reusable widgets
│   │   └── main.dart      # App entry point
│   ├── android/           # Android native code
│   ├── ios/               # iOS native code
│   ├── web/               # Web platform files
│   ├── windows/           # Windows platform files
│   ├── linux/             # Linux platform files
│   ├── macos/             # macOS platform files
│   ├── test/              # Tests
│   ├── pubspec.yaml       # Flutter dependencies
│   ├── analysis_options.yaml # Lint rules
│   ├── .metadata          # Flutter metadata
│   └── README.md          # Frontend documentation
│
└── README.md              # This file

```

## 🚀 Getting Started

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create and activate virtual environment:**
   ```bash
   source myenv/bin/activate
   ```

3. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and JWT secret
   ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Initialize database (optional - auto-creates on startup):**
   ```bash
   # Run the app once and it will auto-create tables and seed data
   ```

6. **Start the development server:**
   ```bash
   python -m uvicorn app.main:app --reload --reload-dir app
   # Or simply:
   python run.py
   ```

   The API will be available at `http://localhost:8000`

### Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on desired platform:**
   ```bash
   # Android emulator
   flutter run -d android

   # iOS simulator
   flutter run -d ios

   # Web
   flutter run -d chrome
   ```

## 📚 API Documentation

Once the backend is running, visit:
- **API Docs (Swagger):** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`

## 🔐 Demo Accounts

When initialized with seed data:
- **Customer:** `customer@neamet.app` / `password123`
- **Delivery:** `delivery@neamet.app` / `password123`

## 🛠️ Tech Stack

### Backend
- **Framework:** FastAPI
- **Database:** PostgreSQL (via Supabase)
- **ORM:** SQLAlchemy
- **Authentication:** JWT with bcrypt
- **Server:** Uvicorn / Gunicorn

### Frontend
- **Framework:** Flutter
- **Language:** Dart
- **State Management:** (Check your implementation)
- **Backend Communication:** HTTP
- **Firebase Integration:** Authentication & Firestore

## 📝 Key Endpoints

- `GET /` - Root endpoint
- `GET /api/health` - Health check
- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `GET /api/auth/me` - Get current user
- `PUT /api/users/me/location` - Update user location
- `GET /api/catalog/bootstrap` - Get products and shops

See [Backend README](backend/README.md) for complete API documentation.

## 🚢 Deployment

### Backend Deployment
The backend is configured for Render deployment using `render.yaml`. Ensure environment variables are set in your Render dashboard before deployment.

```bash
cd backend
# Render will automatically run:
# - buildCommand: pip install -r requirements.txt  
# - startCommand: python run.py
```

### Frontend Deployment
Flutter web and native builds can be generated using:
```bash
cd frontend
flutter build web      # Web
flutter build apk      # Android
flutter build ios      # iOS
```

## 📖 Additional Documentation

- [Backend Documentation](backend/README.md)
- [Frontend Documentation](frontend/README.md)

## 👥 Development Workflow

1. Backend changes: Work in `backend/app/`
2. Frontend changes: Work in `frontend/lib/`
3. Database schema changes: Update `backend/app/models.py` and run migrations
4. Dependencies: Update `backend/requirements.txt` or `frontend/pubspec.yaml`

## ⚠️ Note

- All Flutter-specific files and build artifacts are in the `frontend/` directory
- All Python backend files and dependencies are in the `backend/` directory
- Use absolute imports for clarity and to avoid path confusion
- Keep API contracts synchronized between frontend and backend

