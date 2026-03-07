# Neamet FastAPI Backend

## 1) Configure environment

Create `.env` in `backend/`:

```env
DATABASE_URL=postgresql://postgres.vwtohpwgpcbyeajptith:YOUR_PASSWORD@aws-1-ap-south-1.pooler.supabase.com:6543/postgres
JWT_SECRET=change_this_to_a_long_random_secret
JWT_EXPIRE_HOURS=168
```

You can copy from `.env.example`.

## 2) Install dependencies

```bash
cd backend
source myenv/bin/activate
pip install -r requirements.txt
```

## 3) Run API

```bash
python -m uvicorn app.main:app --reload --reload-dir app
```

## 4) Initialize tables/data in Supabase

Option A (recommended): run app startup once and it auto-creates tables + seed.

Option B (manual SQL): run these in Supabase SQL editor:
1. `sql_schema.sql`
2. `sql_seed.sql`

## Demo Accounts (when seeded by Python startup)

- Customer: `customer@neamet.app` / `password123`
- Delivery: `delivery@neamet.app` / `password123`

## Main APIs

- `GET /`
- `GET /api/health`
- `POST /api/auth/signup`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `PUT /api/users/me/location`
- `GET /api/catalog/bootstrap?range_km=10`
- `GET /api/search?query=potato&range_km=5`
- `POST /api/orders`
- `GET /api/orders/customer`
- `GET /api/delivery/orders/available`
- `GET /api/delivery/orders/my`
- `POST /api/delivery/orders/{shop_order_code}/accept`
- `POST /api/delivery/orders/{shop_order_code}/status`

## Render deployment notes

Set environment variables in Render service:
- `DATABASE_URL` (Supabase transaction pooler URL)
- `JWT_SECRET`
- `JWT_EXPIRE_HOURS`

Start command:

```bash
uvicorn app.main:app --host 0.0.0.0 --port $PORT
```


## Export local data to Supabase

If you have local SQLite data (`neamet.db`) and want to push all rows to Supabase:

```bash
cd backend
source myenv/bin/activate
python scripts/export_to_supabase.py
```

Environment used:
- `SOURCE_DATABASE_URL` (optional, default `sqlite:///./neamet.db`)
- `DATABASE_URL` (required, Supabase Postgres URL)

Note: this script truncates target tables before export.
