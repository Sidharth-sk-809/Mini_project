"""
Quick smoke-test for all /api/shop/* endpoints.
Run from the backend folder with the server on port 8000:
    python test_shop_admin.py
"""
import json, subprocess

BASE = "http://localhost:8000"

def req(method, path, body=None, token=None):
    cmd = ["curl", "-s", "-X", method, BASE + path,
           "-H", "Content-Type: application/json"]
    if token:
        cmd += ["-H", f"Authorization: Bearer {token}"]
    if body:
        cmd += ["-d", json.dumps(body)]
    raw = subprocess.check_output(cmd).decode()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {"_raw": raw}

def section(title):
    print(f"\n{'='*55}")
    print(f"  {title}")
    print('='*55)

# ── 1. Admin creates shop admin account ──────────────────────
section("1. Platform admin login")
admin = req("POST", "/api/auth/login",
            {"email": "admin@neamet.app", "password": "admin123"})
atk = admin.get("access_token")
print(f"  role={admin.get('role')}  user_id={admin.get('user_id')}")
print(f"  token={'OK' if atk else 'MISSING'}")

section("2. Create shop admin (idempotent — 409 is fine if already exists)")
r = req("POST", "/api/admin/shop-admins",
        {"name": "Ravi Kumar", "email": "ravi@greenbasket.com",
         "password": "secret123", "shop_code": "green_basket"}, atk)
print(f"  {r}")

# ── 2. Shop admin login ───────────────────────────────────────
section("3. Shop admin login")
shop = req("POST", "/api/auth/login",
           {"email": "ravi@greenbasket.com", "password": "secret123"})
stk = shop.get("access_token")
print(f"  role={shop.get('role')}  user_id={shop.get('user_id')}")
print(f"  token={'OK' if stk else 'MISSING'}")

# ── 3. Shop info ──────────────────────────────────────────────
section("4. GET /api/shop/me")
info = req("GET", "/api/shop/me", token=stk)
print(json.dumps(info, indent=4))

# ── 4. Shop stats ─────────────────────────────────────────────
section("5. GET /api/shop/stats")
stats = req("GET", "/api/shop/stats", token=stk)
print(json.dumps(stats, indent=4))

# ── 5. List products ──────────────────────────────────────────
section("6. GET /api/shop/products")
prods = req("GET", "/api/shop/products", token=stk)
count = len(prods) if isinstance(prods, list) else "ERROR"
first = prods[0]["name"] if isinstance(prods, list) and prods else "-"
print(f"  {count} products  —  first: {first}")

# ── 6. Add product ────────────────────────────────────────────
section("7. POST /api/shop/products  (add Spinach)")
new_p = req("POST", "/api/shop/products",
            {"shop_code": "green_basket", "code": "gb_spinach_001",
             "name": "Spinach", "subtitle": "Vegetable Shop",
             "image": "assets/products/Spinach.png",
             "price": 35.0, "stock": 20}, stk)
print(f"  name={new_p.get('name')}  code={new_p.get('code')}  stock={new_p.get('stock')}  => {new_p.get('detail','OK')}")

# ── 7. Update full product ────────────────────────────────────
section("8. PUT /api/shop/products/gb_spinach_001  (rename + price)")
upd = req("PUT", "/api/shop/products/gb_spinach_001",
          {"name": "Baby Spinach", "price": 40.0}, stk)
print(f"  name={upd.get('name')}  price={upd.get('price')}  => {upd.get('detail','OK')}")

# ── 8. Stock patch ────────────────────────────────────────────
section("9. PATCH /api/shop/products/gb_spinach_001/stock")
stk_upd = req("PATCH", "/api/shop/products/gb_spinach_001/stock",
              {"stock": 50}, stk)
print(f"  stock={stk_upd.get('stock')}  => {stk_upd.get('detail','OK')}")

# ── 9. List orders ────────────────────────────────────────────
section("10. GET /api/shop/orders")
orders = req("GET", "/api/shop/orders", token=stk)
ocount = len(orders) if isinstance(orders, list) else "ERROR"
print(f"  {ocount} orders")
if isinstance(orders, list) and orders:
    o = orders[0]
    print(f"  First: {o['shop_order_code']}  status={o['status']}  items={len(o['items'])}  total=₹{o['items_total']}")

# ── 10. Filter orders by status ───────────────────────────────
section("11. GET /api/shop/orders?status=confirmed")
conf = req("GET", "/api/shop/orders?status=confirmed", token=stk)
print(f"  {len(conf) if isinstance(conf,list) else conf} confirmed orders")

# ── 11. Access control check ──────────────────────────────────
section("12. ACCESS CONTROL — shop_admin → /api/admin/stats (expect 403)")
ac = req("GET", "/api/admin/stats", token=stk)
print(f"  detail='{ac.get('detail')}'  {'PASS ✓' if ac.get('detail') == 'Admin role required' else 'FAIL ✗'}")

# ── 12. No token check ────────────────────────────────────────
section("13. NO TOKEN → /api/shop/me (expect 401)")
nt = req("GET", "/api/shop/me")
print(f"  detail='{nt.get('detail')}'  {'PASS ✓' if 'authenticated' in str(nt.get('detail','')) else 'FAIL ✗'}")

# ── 13. Delete product ────────────────────────────────────────
section("14. DELETE /api/shop/products/gb_spinach_001")
import subprocess as _sp
cmd = ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
       "-X", "DELETE", f"{BASE}/api/shop/products/gb_spinach_001",
       "-H", f"Authorization: Bearer {stk}"]
code = _sp.check_output(cmd).decode()
print(f"  HTTP {code}  {'PASS ✓' if code == '204' else 'FAIL ✗'}")

print("\n\nAll tests done.\n")
