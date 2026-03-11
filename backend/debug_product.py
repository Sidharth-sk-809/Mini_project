import subprocess, json

BASE = "http://localhost:8000"

def req(method, path, body=None, token=None):
    cmd = ["curl", "-s", "-w", "\nHTTP:%{http_code}", "-X", method, BASE + path,
           "-H", "Content-Type: application/json"]
    if token:
        cmd += ["-H", "Authorization: Bearer " + token]
    if body:
        cmd += ["-d", json.dumps(body)]
    raw = subprocess.check_output(cmd).decode()
    parts = raw.rsplit("\nHTTP:", 1)
    body_str = parts[0]
    code = parts[1] if len(parts) > 1 else "?"
    try:
        return int(code), json.loads(body_str)
    except Exception:
        return (int(code) if code.strip().isdigit() else 0), {"_raw": body_str}

# --- Login as shop admin ---
_, shop = req("POST", "/api/auth/login",
              {"email": "ravi@greenbasket.com", "password": "secret123"})
stok = shop["access_token"]
print(f"Shop admin user_id={shop['user_id']} role={shop['role']}")

# --- Create product ---
code, r = req("POST", "/api/shop/products", {
    "shop_code": "green_basket",
    "code": "gb_spinach_debug",
    "name": "Spinach",
    "subtitle": "Vegetable Shop",
    "image": "",
    "price": 35.0,
    "stock": 20
}, stok)
print(f"\nPOST /api/shop/products  HTTP {code}")
print(json.dumps(r, indent=2))

# --- If created, test update + stock + delete ---
if code == 201:
    pcode = r.get("code")

    code2, r2 = req("PUT", f"/api/shop/products/{pcode}",
                    {"name": "Baby Spinach", "price": 40.0}, stok)
    print(f"\nPUT update  HTTP {code2}")
    print(f"  name={r2.get('name')}  price={r2.get('price')}")

    code3, r3 = req("PATCH", f"/api/shop/products/{pcode}/stock",
                    {"stock": 50}, stok)
    print(f"\nPATCH stock  HTTP {code3}  stock={r3.get('stock')}")

    cmd_del = ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
               "-X", "DELETE", f"{BASE}/api/shop/products/{pcode}",
               "-H", f"Authorization: Bearer {stok}"]
    del_code = subprocess.check_output(cmd_del).decode()
    print(f"\nDELETE  HTTP {del_code}  {'PASS ✓' if del_code == '204' else 'FAIL ✗'}")
else:
    print("\nProduct creation failed — skipping update/delete tests")
