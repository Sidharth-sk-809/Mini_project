# Neamet Admin Panel — Backend API Documentation

## Base URL

```
https://neamet-backend-nfbh.onrender.com

Interactive Swagger UI: https://neamet-backend-nfbh.onrender.com/docs

---

## Authentication

All admin endpoints require a valid JWT with `role = admin`.

### Step 1 — Login

```
POST /api/auth/login
```

**Request body**
```json
{
  "email": "admin@neamet.app",
  "password": "admin123"
}
```

**Response `200 OK`**
```json
{
  "access_token": "<JWT>",
  "token_type": "bearer",
  "user_id": 3,
  "name": "Admin",
  "email": "admin@neamet.app",
  "role": "admin",
  "location": "Edappally, Kochi"
}
```

### Step 2 — Use the token

Include the token in every request header:

```
Authorization: Bearer <access_token>
```

Attempting to call any `/api/admin/*` endpoint without this header, or with a non-admin token, returns:

```json
{ "detail": "Admin role required" }   // 403 Forbidden
```

---

## Endpoints

---

### 1. Stats

#### `GET /api/admin/stats`

Returns a high-level platform summary.

**Response `200 OK`**
```json
{
  "total_products": 42,
  "total_shops": 9,
  "total_users": 120,
  "total_orders": 305,
  "total_revenue": 48250.75,
  "pending_orders": 12,
  "delivered_orders": 289
}
```

| Field | Type | Description |
|---|---|---|
| `total_products` | int | All products in DB |
| `total_shops` | int | All shops in DB |
| `total_users` | int | All registered users |
| `total_orders` | int | All customer orders ever placed |
| `total_revenue` | float | Sum of (price × qty) for all delivered shop orders |
| `pending_orders` | int | Orders with status `placed`, `confirmed`, or `packed` |
| `delivered_orders` | int | Orders with status `delivered` |

---

### 2. Products

#### `GET /api/admin/products`

List all products. Optionally filter by shop.

**Query parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | No | Filter by shop code (e.g. `green_basket`) |

**Response `200 OK`** — array of product objects

```json
[
  {
    "id": 1,
    "code": "green_basket_1_potato",
    "name": "Potato",
    "subtitle": "Vegetable Shop",
    "image": "assets/products/Potato.png",
    "price": 42.0,
    "rating": 4.2,
    "review_count": 32,
    "description": "Potato from Green Basket",
    "stock": 12,
    "shop_id": 1,
    "shop_code": "green_basket",
    "shop_name": "Green Basket"
  }
]
```

---

#### `POST /api/admin/products`

Create a new product.

**Request body**
```json
{
  "shop_code": "green_basket",
  "code": "green_basket_onion",
  "name": "Onion",
  "subtitle": "Vegetable Shop",
  "image": "assets/products/Onion.png",
  "price": 35.0,
  "rating": 4.3,
  "review_count": 18,
  "description": "Fresh onions from Green Basket",
  "stock": 20
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `shop_code` | string | **Yes** | Must match an existing shop |
| `code` | string | **Yes** | Unique across all products, min 2 chars |
| `name` | string | **Yes** | min 2 chars |
| `subtitle` | string | No | defaults to `""` |
| `image` | string | No | Asset path or URL, defaults to `""` |
| `price` | float | **Yes** | Must be > 0 |
| `rating` | float | No | 0–5, defaults to `4.5` |
| `review_count` | int | No | ≥ 0, defaults to `0` |
| `description` | string | No | defaults to `""` |
| `stock` | int | No | ≥ 0, defaults to `10` |

**Response `201 Created`** — the created product object (same shape as GET)

**Errors**
- `404` — `shop_code` not found
- `409` — `code` already exists

---

#### `PUT /api/admin/products/{product_code}`

Update any fields of an existing product. All fields are optional (send only what you want to change).

**Path parameter** — `product_code` e.g. `green_basket_onion`

**Request body** (all fields optional)
```json
{
  "name": "Red Onion",
  "price": 38.0,
  "stock": 15,
  "description": "Premium red onions"
}
```

| Field | Type | Constraints |
|---|---|---|
| `name` | string | min 2 chars |
| `subtitle` | string | — |
| `image` | string | — |
| `price` | float | > 0 |
| `rating` | float | 0–5 |
| `review_count` | int | ≥ 0 |
| `description` | string | — |
| `stock` | int | ≥ 0 |

**Response `200 OK`** — updated product object

**Errors**
- `404` — product not found

---

#### `PATCH /api/admin/products/{product_code}/stock`

Update only the stock quantity (convenience endpoint for restocking).

**Path parameter** — `product_code`

**Request body**
```json
{ "stock": 50 }
```

| Field | Type | Constraints |
|---|---|---|
| `stock` | int | **Required**, ≥ 0 |

**Response `200 OK`** — updated product object

**Errors**
- `404` — product not found

---

#### `DELETE /api/admin/products/{product_code}`

Delete a product permanently.

**Path parameter** — `product_code`

**Response `204 No Content`**

**Errors**
- `404` — product not found

---

### 3. Shops

#### `GET /api/admin/shops`

List all shops.

**Response `200 OK`**
```json
[
  {
    "id": 1,
    "code": "green_basket",
    "name": "Green Basket",
    "shop_type": "Vegetable Shop",
    "distance_km": 2,
    "delivery_available": true,
    "product_count": 4
  }
]
```

---

#### `POST /api/admin/shops`

Create a new shop.

**Request body**
```json
{
  "code": "fresh_dairy",
  "name": "Fresh Dairy",
  "shop_type": "Dairy Shop",
  "distance_km": 3,
  "delivery_available": true
}
```

| Field | Type | Required | Constraints |
|---|---|---|---|
| `code` | string | **Yes** | Unique, min 2 chars |
| `name` | string | **Yes** | min 2 chars |
| `shop_type` | string | No | defaults to `""` |
| `distance_km` | int | No | ≥ 0, defaults to `5` |
| `delivery_available` | bool | No | defaults to `true` |

**Response `201 Created`** — the created shop object

**Errors**
- `409` — `code` already exists

---

#### `PUT /api/admin/shops/{shop_code}`

Update shop details. All fields optional.

**Path parameter** — `shop_code`

**Request body** (all fields optional)
```json
{
  "name": "Fresh Dairy Plus",
  "delivery_available": false
}
```

| Field | Type | Constraints |
|---|---|---|
| `name` | string | — |
| `shop_type` | string | — |
| `distance_km` | int | ≥ 0 |
| `delivery_available` | bool | — |

**Response `200 OK`** — updated shop object

**Errors**
- `404` — shop not found

---

#### `DELETE /api/admin/shops/{shop_code}`

Delete a shop permanently.

> **Important:** A shop cannot be deleted if it still has products. Delete all its products first.

**Path parameter** — `shop_code`

**Response `204 No Content`**

**Errors**
- `404` — shop not found
- `409` — shop has products (message includes product count)

---

### 4. Users

#### `GET /api/admin/users`

List all registered users. Optionally filter by role.

**Query parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `role` | string | No | Filter by role: `customer`, `delivery_person`, or `admin` |

**Response `200 OK`**
```json
[
  {
    "id": 1,
    "name": "Demo Customer",
    "email": "customer@neamet.app",
    "role": "customer",
    "location": "Edappally, Kochi",
    "created_at": "2026-03-01T10:00:00"
  }
]
```

Results are ordered by `created_at` descending (newest first).

---

### 5. Orders

#### `GET /api/admin/orders`

List all customer orders. Optionally filter by status.

**Query parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `status` | string | No | Filter by order status (see table below) |

**Order status values**

| Status | Meaning |
|---|---|
| `placed` | Order just created |
| `confirmed` | Shop confirmed |
| `packed` | Order packed and ready |
| `ready_for_pickup` | Order ready for customer shop pickup |
| `out_for_delivery` | Delivery person has picked up the order |
| `delivered` | Order delivered to customer |
| `cancelled` | Order cancelled |

**Response `200 OK`**
```json
[
  {
    "id": 10,
    "order_code": "ORD-20260301-ABCD",
    "customer_user_id": 1,
    "delivery_address": "Edappally, Kochi",
    "status": "delivered",
    "created_at": "2026-03-01T14:30:00",
    "total_items": 3,
    "grand_total": 145.50
  }
]
```

| Field | Description |
|---|---|
| `total_items` | Sum of all item quantities across all shop orders |
| `grand_total` | Sum of (price × qty) for all items + delivery fees |

Results are ordered by `created_at` descending (newest first).

---

## Common Error Responses

| Status | When |
|---|---|
| `401 Unauthorized` | Missing or invalid JWT token |
| `403 Forbidden` | Token is valid but role is not `admin` |
| `404 Not Found` | Resource (product / shop) does not exist |
| `409 Conflict` | Duplicate `code` on create, or shop still has products on delete |
| `422 Unprocessable Entity` | Request body validation failed (missing required field, value out of range, etc.) |

---

## Quick Reference

| Method | Endpoint | Description |
|---|---|---|
| GET | `/api/admin/stats` | Platform statistics |
| GET | `/api/admin/products` | List products (`?shop_code=`) |
| POST | `/api/admin/products` | Create product |
| PUT | `/api/admin/products/{code}` | Update product |
| PATCH | `/api/admin/products/{code}/stock` | Update stock only |
| DELETE | `/api/admin/products/{code}` | Delete product |
| GET | `/api/admin/shops` | List shops |
| POST | `/api/admin/shops` | Create shop |
| PUT | `/api/admin/shops/{code}` | Update shop |
| DELETE | `/api/admin/shops/{code}` | Delete shop |
| GET | `/api/admin/users` | List users (`?role=`) |
| GET | `/api/admin/orders` | List orders (`?status=`) |
