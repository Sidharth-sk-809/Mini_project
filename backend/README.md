# Neamet FastAPI Backend

**Live URL:** https://mini-project-8sdo.onrender.com  
**Swagger UI:** https://mini-project-8sdo.onrender.com/docs

---

## 1. Environment Setup

Create `.env` in `backend/`:

```env
DATABASE_URL=postgresql://postgres:<password>@<host>:6543/postgres
JWT_SECRET=change_this_to_a_long_random_secret
JWT_EXPIRE_HOURS=168
```

## 2. Install Dependencies

```bash
cd backend
source myenv/bin/activate
pip install -r requirements.txt
```

## 3. Run Locally

```bash
python run.py
# Available at http://localhost:8000
```

Tables and seed data are created automatically on first startup.

## 4. Manual DB Setup (optional)

Run these in the Supabase SQL editor if you prefer manual setup:
1. `sql_schema.sql`
2. `sql_seed.sql`

---

## Demo Accounts

| Role | Email | Password |
|---|---|---|
| Customer | customer@neamet.app | password123 |
| Delivery Person | delivery@neamet.app | password123 |
| Admin | admin@neamet.app | admin123 |

---

## API Reference

### Health
- `GET /` — root
- `GET /api/health` — health check

### Auth
- `POST /api/auth/signup` — register (role: customer | delivery_person | admin)
- `POST /api/auth/login` — login → `{ access_token, token_type }`
- `GET /api/auth/me` — current user (requires Bearer token)
- `PUT /api/users/me/location` — update GPS coordinates

### Catalog
- `GET /api/catalog/bootstrap?range_km=10` — shops + products in range
- `GET /api/search?query=potato&range_km=5` — product search

### Orders (customer role)
- `POST /api/orders` — place order
- `GET /api/orders/customer` — my order history
- `POST /api/orders/{customer_order_code}/cancel` — cancel order
- `POST /api/orders/{customer_order_code}/advance` — advance status

### Delivery (delivery_person role)
- `GET /api/delivery/orders/available` — unassigned orders
- `GET /api/delivery/orders/my` — my accepted orders
- `POST /api/delivery/orders/{shop_order_code}/accept` — accept order
- `POST /api/delivery/orders/{shop_order_code}/status` — update status

### Admin (admin role — `Authorization: Bearer <token>`)
- `GET /api/admin/stats` — platform statistics
- `GET /api/admin/products` — list products (`?shop_code=` filter)
- `POST /api/admin/products` — create product
- `PUT /api/admin/products/{code}` — update product
- `PATCH /api/admin/products/{code}/stock` — update stock only
- `DELETE /api/admin/products/{code}` — delete product
- `GET /api/admin/shops` — list shops
- `POST /api/admin/shops` — create shop
- `PUT /api/admin/shops/{code}` — update shop
- `DELETE /api/admin/shops/{code}` — delete shop (blocked if products exist)
- `GET /api/admin/users` — list users (`?role=` filter)
- `GET /api/admin/orders` — list orders (`?status=` filter)

---

## Render Deployment

Required environment variables in Render dashboard:
- `DATABASE_URL`
- `JWT_SECRET`
- `JWT_EXPIRE_HOURS`

`render.yaml` at project root sets `rootDir: backend`.  
Start command: `python run.py`

---

## Export Local Data to Supabase

```bash
cd backend
source myenv/bin/activate
python scripts/export_to_supabase.py
```

Uses `SOURCE_DATABASE_URL` (default: `sqlite:///./neamet.db`) and `DATABASE_URL`.  
**Warning:** truncates target tables before export.
