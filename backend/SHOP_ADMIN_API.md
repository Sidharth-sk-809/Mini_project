# Neamet — Shop Admin Panel API Documentation

## Overview

Each shop on the platform can have a dedicated **shop admin** account. A shop admin can:

- Manage their shop's **product catalogue** (add, edit, update stock, delete)
- **Monitor all orders** placed with their shop
- **Advance order status** through the fulfilment pipeline
- View **shop-level stats** (revenue, stock alerts, pending orders)

Shop admins only ever see data belonging to **their own shop**. Platform admins (`role = admin`) can access all shop admin endpoints by appending `?shop_code=<code>` to any request.

---

## Base URL

```
https://neamet-backend-nfbh.onrender.com
```

Interactive Swagger UI: `https://neamet-backend-nfbh.onrender.com/docs`

---

## Roles

| Role | Source | Access |
|---|---|---|
| `admin` | Platform administrator | All endpoints — supply `?shop_code=` to target a specific shop |
| `shop_admin` | Created by platform admin, linked to a specific shop | Only `/api/shop/*` endpoints, scoped to their shop |

---

## Setting Up a Shop Admin Account

A **platform admin** must first create the shop admin account and link it to a shop.

### `POST /api/admin/shop-admins`

**Header:** `Authorization: Bearer <platform_admin_jwt>`

**Request body**
```json
{
  "name": "Ravi Kumar",
  "email": "ravi@greenbasket.com",
  "password": "secret123",
  "shop_code": "green_basket"
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | string | **Yes** | Shop admin's display name (min 2 chars) |
| `email` | string | **Yes** | Unique email address |
| `password` | string | **Yes** | Login password (min 6 chars) |
| `shop_code` | string | **Yes** | Code of the shop to link this admin to |

**Response `201 Created`**
```json
{
  "id": 25,
  "name": "Ravi Kumar",
  "email": "ravi@greenbasket.com",
  "role": "shop_admin",
  "location": "",
  "created_at": "2026-03-11T09:00:00"
}
```

**Errors**
- `404` — `shop_code` not found
- `409` — email already registered

---

## Authentication

Shop admins log in via the standard login endpoint.

### `POST /api/auth/login`

**Request body**
```json
{
  "email": "ravi@greenbasket.com",
  "password": "secret123"
}
```

**Response `200 OK`**
```json
{
  "access_token": "<JWT>",
  "token_type": "bearer",
  "user_id": 25,
  "name": "Ravi Kumar",
  "email": "ravi@greenbasket.com",
  "role": "shop_admin",
  "location": ""
}
```

### Using the Token

Include the JWT in every subsequent request:

```
Authorization: Bearer <access_token>
```

Calling any `/api/shop/*` endpoint without this header, or with a non-shop-admin token, returns:

```json
{ "detail": "Shop admin role required" }   // 403 Forbidden
```

---

## Endpoints

---

### 1. Shop Info

#### `GET /api/shop/me`

Returns the details of the shop this admin manages.

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop (omit when calling as shop_admin) |

**Response `200 OK`**
```json
{
  "id": 1,
  "code": "green_basket",
  "name": "Green Basket",
  "shop_type": "Vegetable Shop",
  "distance_km": 2,
  "delivery_available": true,
  "product_count": 8
}
```

---

### 2. Shop Stats

#### `GET /api/shop/stats`

Returns a summary of the shop's current state.

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

**Response `200 OK`**
```json
{
  "shop_id": 1,
  "shop_code": "green_basket",
  "shop_name": "Green Basket",
  "total_products": 8,
  "out_of_stock_products": 1,
  "total_orders": 45,
  "pending_orders": 3,
  "ready_orders": 1,
  "delivered_orders": 38,
  "total_revenue": 12450.75
}
```

| Field | Description |
|---|---|
| `out_of_stock_products` | Products with `stock = 0` |
| `pending_orders` | Shop orders with status `placed`, `confirmed`, or `packed` |
| `ready_orders` | Shop orders with status `ready_for_pickup` |
| `delivered_orders` | Shop orders with status `delivered` |
| `total_revenue` | Sum of (price × qty) for all **delivered** shop orders |

---

### 3. Products

#### `GET /api/shop/products`

List all products in the shop, sorted by name.

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

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

#### `POST /api/shop/products`

Add a new product to the shop.

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

**Request body**
```json
{
  "shop_code": "green_basket",
  "code": "green_basket_carrot",
  "name": "Carrot",
  "subtitle": "Vegetable Shop",
  "image": "assets/products/Carrot.png",
  "price": 28.0,
  "rating": 4.4,
  "review_count": 10,
  "description": "Fresh carrots from Green Basket",
  "stock": 30
}
```

> **Note:** `shop_code` in the body is required for schema validation but is ignored for shop admins — the product is always created in the admin's own shop.

| Field | Type | Required | Constraints |
|---|---|---|---|
| `shop_code` | string | **Yes** | Must match the admin's shop (enforced server-side) |
| `code` | string | **Yes** | Unique across all products, min 2 chars |
| `name` | string | **Yes** | min 2 chars |
| `subtitle` | string | No | defaults to `""` |
| `image` | string | No | Asset path or URL, defaults to `""` |
| `price` | float | **Yes** | Must be > 0 |
| `rating` | float | No | 0–5, defaults to `4.5` |
| `review_count` | int | No | ≥ 0, defaults to `0` |
| `description` | string | No | defaults to `""` |
| `stock` | int | No | ≥ 0, defaults to `10` |

**Response `201 Created`** — the created product object

**Errors**
- `404` — shop not found
- `409` — `code` already exists

---

#### `PUT /api/shop/products/{product_code}`

Update any fields of a product. All fields are optional — send only what needs to change.

**Path parameter** — `product_code`, e.g. `green_basket_carrot`

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

**Request body** (all fields optional)
```json
{
  "name": "Baby Carrot",
  "price": 32.0,
  "stock": 20,
  "description": "Tender baby carrots"
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
- `404` — product not found in this shop

---

#### `PATCH /api/shop/products/{product_code}/stock`

Update only the stock quantity. Use this for quick restocking without touching any other product fields.

**Path parameter** — `product_code`

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

**Request body**
```json
{ "stock": 50 }
```

| Field | Type | Constraints |
|---|---|---|
| `stock` | int | **Required**, ≥ 0 |

**Response `200 OK`** — updated product object

**Errors**
- `404` — product not found in this shop

---

#### `DELETE /api/shop/products/{product_code}`

Delete a product from the shop permanently.

**Path parameter** — `product_code`

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

**Response `204 No Content`**

**Errors**
- `404` — product not found in this shop

---

### 4. Orders

#### `GET /api/shop/orders`

List all orders placed with this shop, newest first. Optionally filter by status.

**Query parameters**

| Param | Type | Required | Description |
|---|---|---|---|
| `status` | string | No | Filter by order status (see table below) |
| `shop_code` | string | Admin only | Target shop (platform admin only) |

**Order status values**

| Status | Meaning |
|---|---|
| `placed` | Order just received from customer |
| `confirmed` | Shop has confirmed the order |
| `packed` | Items packed and ready |
| `ready_for_pickup` | Ready for customer pickup (pickup orders) or awaiting delivery person |
| `out_for_delivery` | Delivery person has collected the order |
| `delivered` | Order delivered to customer |
| `cancelled` | Order cancelled |

**Response `200 OK`** — array of shop order objects
```json
[
  {
    "id": 12,
    "shop_order_code": "SO-ORD-1741680000-0",
    "customer_order_id": 10,
    "customer_name": "Demo Customer",
    "delivery_address": "Edappally, Kochi",
    "status": "confirmed",
    "delivery_job_status": "available",
    "selected_delivery_type": "home_delivery",
    "delivery_fee": 26.0,
    "eta_minutes": 22,
    "created_at": "2026-03-11T09:00:00",
    "items": [
      {
        "product_id": "green_basket_1_potato",
        "product_name": "Potato",
        "quantity": 2,
        "price": 42.0
      }
    ],
    "items_total": 84.0,
    "assigned_delivery_name": null
  }
]
```

| Field | Description |
|---|---|
| `delivery_job_status` | Delivery-side status: `available`, `accepted`, `picked_up`, `delivered`, `cancelled` |
| `selected_delivery_type` | `home_delivery` or `shop_pickup` |
| `items_total` | Sum of (price × qty) for all items (excludes delivery fee) |
| `assigned_delivery_name` | Name of the delivery person (if assigned) |

---

#### `POST /api/shop/orders/{shop_order_code}/status`

Advance or cancel an order. Shop admins control the shop-side fulfilment flow.

**Path parameter** — `shop_order_code`, e.g. `SO-ORD-1741680000-0`

**Query parameters** *(platform admin only)*

| Param | Type | Required | Description |
|---|---|---|---|
| `shop_code` | string | Admin only | Target shop |

**Request body**
```json
{ "status": "packed" }
```

**Allowed status values**

| Value | Effect |
|---|---|
| `confirmed` | Shop confirms the order (from `placed`) |
| `packed` | Items packed; order ready to be dispatched |
| `ready_for_pickup` | Marks the order as packed **and** opens the delivery job (`delivery_job_status → available`) so a delivery person can accept it |
| `cancelled` | Cancels the order; sets `delivery_job_status → cancelled` |

> **Status transition rule:** You cannot update an order that is already `out_for_delivery`, `delivered`, or `cancelled`.

**Recommended flow for `home_delivery` orders:**
```
placed → confirmed → packed → ready_for_pickup
                                       ↓
                              (delivery person accepts)
                                       ↓
                              out_for_delivery → delivered
```

**Recommended flow for `shop_pickup` orders:**
```
placed → confirmed → packed → ready_for_pickup → (customer collects) → delivered
```

**Response `200 OK`** — updated shop order object (same shape as GET /api/shop/orders items)

**Errors**
- `404` — order not found in this shop
- `409` — order is already `out_for_delivery`, `delivered`, or `cancelled`

---

## Common Error Responses

| Status | When |
|---|---|
| `401 Unauthorized` | Missing or expired JWT token |
| `403 Forbidden` | Token valid but role is not `shop_admin` or `admin`; or `shop_admin` has no assigned shop |
| `404 Not Found` | Resource (product / shop / order) does not exist in this shop |
| `409 Conflict` | Duplicate product code on create; or order status prevents the update |
| `422 Unprocessable Entity` | Request body validation failed (missing required field, value out of range, etc.) |

---

## Database Migration for Supabase

If your Supabase database already exists, run these two statements in the Supabase SQL editor to enable shop admin support:

```sql
-- 1. Add managed_shop_id column to users
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS managed_shop_id BIGINT NULL
    REFERENCES shops(id) ON DELETE SET NULL;

-- 2. Allow shop_admin as a valid role
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users
  ADD CONSTRAINT users_role_check
    CHECK (role IN ('customer', 'delivery_person', 'admin', 'shop_admin'));
```

> For fresh deployments, the updated `sql_schema.sql` already includes these changes.

---

## Quick Reference

| Method | Endpoint | Description |
|---|---|---|
| POST | `/api/admin/shop-admins` | (Platform admin) Create a shop admin account |
| POST | `/api/auth/login` | Shop admin login |
| GET | `/api/shop/me` | Get own shop info |
| GET | `/api/shop/stats` | Shop statistics |
| GET | `/api/shop/products` | List own shop's products |
| POST | `/api/shop/products` | Add a product |
| PUT | `/api/shop/products/{code}` | Update product details |
| PATCH | `/api/shop/products/{code}/stock` | Update stock only |
| DELETE | `/api/shop/products/{code}` | Delete a product |
| GET | `/api/shop/orders` | List all orders (`?status=`) |
| POST | `/api/shop/orders/{code}/status` | Update order status |
