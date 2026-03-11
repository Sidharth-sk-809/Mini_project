from datetime import datetime

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .auth import (
    create_access_token,
    get_current_user,
    hash_password,
    require_admin_user,
    require_delivery_user,
    require_shop_admin,
    verify_password,
)
from .database import Base, SessionLocal, engine, get_db
from .models import CustomerOrder, Product, Shop, ShopOrder, ShopOrderItem, User
from .schemas import (
    AdminOrderResponse,
    AdminProductCreate,
    AdminProductResponse,
    AdminProductUpdate,
    AdminShopCreate,
    AdminShopResponse,
    AdminShopUpdate,
    AdminStatsResponse,
    AdminStockUpdate,
    AdminUserResponse,
    AuthLoginRequest,
    AuthResponse,
    AuthSignupRequest,
    CatalogBootstrapResponse,
    CreateOrderRequest,
    DeliveryStatusUpdateRequest,
    HealthResponse,
    LocationUpdateRequest,
    OrderDTO,
    ProductDTO,
    SearchResponse,
    ShopAdminCreateRequest,
    ShopAdminOrderResponse,
    ShopAdminOrderItemResponse,
    ShopAdminOrderStatusUpdate,
    ShopAdminStatsResponse,
    ShopDTO,
    ShopOrderDTO,
    ShopOrderItemDTO,
)
from .seed import CATEGORIES, RANGES_KM, seed_data, seed_demo_orders

app = FastAPI(title="Neamet API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup_event():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_data(db)
        seed_demo_orders(db)
    finally:
        db.close()




@app.get('/')
def root():
    return {
        'message': 'Neamet API is running',
        'docs': '/docs',
        'health': '/api/health',
    }

@app.get("/api/health", response_model=HealthResponse)
def health():
    return HealthResponse(status="ok")


@app.post("/api/auth/signup", response_model=AuthResponse)
def signup(payload: AuthSignupRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already exists")

    user = User(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role,
        location="Edappally, Kochi",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.id, user.email, user.role)
    return AuthResponse(
        access_token=token,
        user_id=user.id,
        name=user.name,
        email=user.email,
        role=user.role,
        location=user.location,
    )


@app.post("/api/auth/login", response_model=AuthResponse)
def login(payload: AuthLoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(user.id, user.email, user.role)
    return AuthResponse(
        access_token=token,
        user_id=user.id,
        name=user.name,
        email=user.email,
        role=user.role,
        location=user.location,
    )


@app.get("/api/auth/me", response_model=AuthResponse)
def me(current_user: User = Depends(get_current_user)):
    token = create_access_token(current_user.id, current_user.email, current_user.role)
    return AuthResponse(
        access_token=token,
        user_id=current_user.id,
        name=current_user.name,
        email=current_user.email,
        role=current_user.role,
        location=current_user.location,
    )


@app.put("/api/users/me/location", response_model=AuthResponse)
def update_location(
    payload: LocationUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    current_user.location = payload.location
    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    token = create_access_token(current_user.id, current_user.email, current_user.role)
    return AuthResponse(
        access_token=token,
        user_id=current_user.id,
        name=current_user.name,
        email=current_user.email,
        role=current_user.role,
        location=current_user.location,
    )


def _shop_to_dto(shop: Shop, product_names: list[str]) -> ShopDTO:
    return ShopDTO(
        id=shop.code,
        name=shop.name,
        type=shop.shop_type,
        distance_km=shop.distance_km,
        delivery_available=shop.delivery_available,
        product_names=product_names,
    )


def _product_to_dto(product: Product, shop: Shop) -> ProductDTO:
    return ProductDTO(
        id=product.code,
        name=product.name,
        subtitle=product.subtitle,
        price=product.price,
        image="",
        rating=product.rating,
        review_count=product.review_count,
        seller=shop.name,
        vendor="Neamet",
        description=product.description,
        shop_id=shop.code,
        stock=product.stock,
        shop_distance_km=float(shop.distance_km),
        delivery_available=shop.delivery_available,
        shop_type=shop.shop_type,
    )


@app.get("/api/catalog/bootstrap", response_model=CatalogBootstrapResponse)
def catalog_bootstrap(range_km: int = 10, db: Session = Depends(get_db)):
    if range_km not in (2, 5, 10):
        range_km = 5

    shops = db.query(Shop).filter(Shop.distance_km <= range_km).all()
    products = (
        db.query(Product)
        .join(Shop, Product.shop_id == Shop.id)
        .filter(Shop.distance_km <= range_km)
        .all()
    )

    shop_product_names: dict[int, list[str]] = {}
    for p in products:
        shop_product_names.setdefault(p.shop_id, []).append(p.name)

    shop_dtos = [_shop_to_dto(shop, sorted(set(shop_product_names.get(shop.id, [])))) for shop in shops]
    shop_map = {shop.id: shop for shop in shops}
    product_dtos = [_product_to_dto(p, shop_map[p.shop_id]) for p in products if p.shop_id in shop_map]

    return CatalogBootstrapResponse(
        categories=CATEGORIES,
        ranges_km=RANGES_KM,
        shops=shop_dtos,
        products=product_dtos,
    )


@app.get("/api/search", response_model=SearchResponse)
def search(query: str, range_km: int = 5, db: Session = Depends(get_db)):
    q = query.strip().lower()
    if not q:
        return SearchResponse(query=query, query_type="none", products=[], shops=[])

    shops = db.query(Shop).filter(Shop.distance_km <= range_km).all()
    shop_ids = [shop.id for shop in shops]

    products = (
        db.query(Product)
        .filter(Product.shop_id.in_(shop_ids), Product.name.ilike(f"%{q}%"))
        .all()
    )

    if products:
        shop_map = {shop.id: shop for shop in shops}
        result_products = [_product_to_dto(p, shop_map[p.shop_id]) for p in products if p.shop_id in shop_map]
        return SearchResponse(query=query, query_type="product", products=result_products, shops=[])

    matching_shops = [shop for shop in shops if q in shop.name.lower()]
    if matching_shops:
        result_shops = []
        for shop in matching_shops:
            names = [p.name for p in db.query(Product).filter(Product.shop_id == shop.id).all()]
            result_shops.append(_shop_to_dto(shop, sorted(set(names))))
        return SearchResponse(query=query, query_type="shop", products=[], shops=result_shops)

    return SearchResponse(query=query, query_type="none", products=[], shops=[])


def _shop_order_to_dto(db: Session, shop_order: ShopOrder) -> ShopOrderDTO:
    shop = db.query(Shop).filter(Shop.id == shop_order.shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    item_dtos: list[ShopOrderItemDTO] = []
    items_total = 0.0
    for item in shop_order.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        if not product:
            continue
        item_dtos.append(
            ShopOrderItemDTO(
                product_id=product.code,
                product_name=product.name,
                image="",
                subtitle=product.subtitle,
                quantity=item.quantity,
                price=item.price,
            )
        )
        items_total += item.price * item.quantity

    return ShopOrderDTO(
        id=shop_order.shop_order_code,
        shop_id=shop.code,
        shop_name=shop.name,
        status=shop_order.status,
        delivery_job_status=shop_order.delivery_job_status,
        selected_delivery_type=shop_order.selected_delivery_type,
        delivery_fee=shop_order.delivery_fee,
        eta_minutes=shop_order.eta_minutes,
        items_total=items_total,
        items=item_dtos,
        assigned_delivery_user_id=shop_order.assigned_delivery_user_id,
        assigned_delivery_name=shop_order.assigned_delivery_name,
    )


def _order_to_dto(db: Session, order: CustomerOrder) -> OrderDTO:
    return OrderDTO(
        id=order.order_code,
        delivery_address=order.delivery_address,
        status=order.status,
        created_at=order.created_at,
        shop_orders=[_shop_order_to_dto(db, so) for so in order.shop_orders],
    )


@app.post("/api/orders", response_model=OrderDTO)
def create_order(
    payload: CreateOrderRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    order_code = f"ORD-{int(datetime.utcnow().timestamp())}"
    order = CustomerOrder(
        order_code=order_code,
        customer_user_id=current_user.id,
        delivery_address=payload.delivery_address,
        status="placed",
        created_at=datetime.utcnow(),
    )
    db.add(order)
    db.flush()

    for idx, so in enumerate(payload.shop_orders):
        shop = db.query(Shop).filter(Shop.code == so.shop_id).first()
        if not shop:
            continue

        fee = 0.0 if so.delivery_type == "shop_pickup" else float(20 + shop.distance_km * 3)
        status = "confirmed" if so.delivery_type == "home_delivery" else "ready_for_pickup"
        job_status = "available" if so.delivery_type == "home_delivery" else "delivered"

        shop_order = ShopOrder(
            shop_order_code=f"SO-{order_code}-{idx}",
            customer_order_id=order.id,
            shop_id=shop.id,
            status=status,
            delivery_job_status=job_status,
            selected_delivery_type=so.delivery_type,
            delivery_fee=fee,
            eta_minutes=20 + shop.distance_km,
        )
        db.add(shop_order)
        db.flush()

        for item in so.items:
            product = db.query(Product).filter(Product.code == item.product_id).first()
            if not product or product.shop_id != shop.id:
                continue
            db.add(
                ShopOrderItem(
                    shop_order_id=shop_order.id,
                    product_id=product.id,
                    quantity=item.quantity,
                    price=product.price,
                )
            )

    db.commit()
    db.refresh(order)
    return _order_to_dto(db, order)


@app.get("/api/orders/customer", response_model=list[OrderDTO])
def customer_orders(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    rows = (
        db.query(CustomerOrder)
        .filter(CustomerOrder.customer_user_id == current_user.id)
        .order_by(CustomerOrder.created_at.desc())
        .all()
    )
    return [_order_to_dto(db, order) for order in rows]


@app.get("/api/delivery/orders/available", response_model=list[OrderDTO])
def available_delivery_orders(
    db: Session = Depends(get_db),
    _: User = Depends(require_delivery_user),
):
    rows = (
        db.query(CustomerOrder)
        .join(ShopOrder, ShopOrder.customer_order_id == CustomerOrder.id)
        .filter(
            ShopOrder.delivery_job_status == "available",
            ShopOrder.assigned_delivery_user_id.is_(None),
        )
        .order_by(CustomerOrder.created_at.desc())
        .all()
    )
    seen = set()
    unique_orders = []
    for order in rows:
        if order.id in seen:
            continue
        seen.add(order.id)
        unique_orders.append(order)
    return [_order_to_dto(db, order) for order in unique_orders]


@app.get("/api/delivery/orders/my", response_model=list[OrderDTO])
def my_delivery_orders(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_delivery_user),
):
    rows = (
        db.query(CustomerOrder)
        .join(ShopOrder, ShopOrder.customer_order_id == CustomerOrder.id)
        .filter(ShopOrder.assigned_delivery_user_id == current_user.id)
        .order_by(CustomerOrder.created_at.desc())
        .all()
    )
    seen = set()
    unique_orders = []
    for order in rows:
        if order.id in seen:
            continue
        seen.add(order.id)
        unique_orders.append(order)
    return [_order_to_dto(db, order) for order in unique_orders]


@app.post("/api/delivery/orders/{shop_order_code}/accept", response_model=ShopOrderDTO)
def accept_delivery_order(
    shop_order_code: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_delivery_user),
):
    so = db.query(ShopOrder).filter(ShopOrder.shop_order_code == shop_order_code).first()
    if not so:
        raise HTTPException(status_code=404, detail="Shop order not found")
    if so.delivery_job_status != "available" or so.assigned_delivery_user_id is not None:
        raise HTTPException(status_code=409, detail="Order already assigned")

    so.delivery_job_status = "accepted"
    so.status = "out_for_delivery"
    so.assigned_delivery_user_id = current_user.id
    so.assigned_delivery_name = current_user.name
    db.add(so)
    db.commit()
    db.refresh(so)

    return _shop_order_to_dto(db, so)


@app.post("/api/delivery/orders/{shop_order_code}/status", response_model=ShopOrderDTO)
def update_delivery_status(
    shop_order_code: str,
    payload: DeliveryStatusUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_delivery_user),
):
    so = db.query(ShopOrder).filter(ShopOrder.shop_order_code == shop_order_code).first()
    if not so:
        raise HTTPException(status_code=404, detail="Shop order not found")

    if so.assigned_delivery_user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Order not assigned to this delivery user")

    so.delivery_job_status = payload.status
    if payload.status == "picked_up":
        so.status = "out_for_delivery"
    elif payload.status == "delivered":
        so.status = "delivered"

    db.add(so)
    db.commit()
    db.refresh(so)
    return _shop_order_to_dto(db, so)


@app.post("/api/orders/{shop_order_code}/cancel", response_model=ShopOrderDTO)
def cancel_order_before_dispatch(
    shop_order_code: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    so = db.query(ShopOrder).filter(ShopOrder.shop_order_code == shop_order_code).first()
    if not so:
      raise HTTPException(status_code=404, detail="Shop order not found")

    parent = db.query(CustomerOrder).filter(CustomerOrder.id == so.customer_order_id).first()
    if not parent or parent.customer_user_id != current_user.id:
      raise HTTPException(status_code=403, detail="Forbidden")

    if so.status in ("out_for_delivery", "delivered", "cancelled"):
      raise HTTPException(status_code=409, detail="Cannot cancel at current status")

    so.status = "cancelled"
    so.delivery_job_status = "cancelled"
    db.add(so)
    db.commit()
    db.refresh(so)
    return _shop_order_to_dto(db, so)


@app.post("/api/orders/{shop_order_code}/advance", response_model=ShopOrderDTO)
def advance_order_status(
    shop_order_code: str,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    so = db.query(ShopOrder).filter(ShopOrder.shop_order_code == shop_order_code).first()
    if not so:
      raise HTTPException(status_code=404, detail="Shop order not found")

    flow = ["placed", "confirmed", "packed", "out_for_delivery", "delivered"]
    if so.status in ("cancelled", "delivered"):
      return _shop_order_to_dto(db, so)

    try:
      idx = flow.index(so.status)
      so.status = flow[min(idx + 1, len(flow) - 1)]
    except ValueError:
      so.status = "confirmed"

    if so.status == "delivered":
      so.delivery_job_status = "delivered"
    elif so.status == "out_for_delivery" and so.delivery_job_status == "available":
      so.delivery_job_status = "accepted"

    db.add(so)
    db.commit()
    db.refresh(so)
    return _shop_order_to_dto(db, so)


# ════════════════════════════════════════════════════════════════
#  ADMIN ENDPOINTS
# ════════════════════════════════════════════════════════════════

def _product_to_admin_dto(product: Product, db: Session) -> AdminProductResponse:
    shop = db.query(Shop).filter(Shop.id == product.shop_id).first()
    return AdminProductResponse(
        id=product.id,
        code=product.code,
        name=product.name,
        subtitle=product.subtitle,
        image=product.image,
        price=product.price,
        rating=product.rating,
        review_count=product.review_count,
        description=product.description,
        stock=product.stock,
        shop_id=product.shop_id,
        shop_code=shop.code if shop else "",
        shop_name=shop.name if shop else "",
    )


def _shop_to_admin_dto(shop: Shop, db: Session) -> AdminShopResponse:
    product_count = db.query(Product).filter(Product.shop_id == shop.id).count()
    return AdminShopResponse(
        id=shop.id,
        code=shop.code,
        name=shop.name,
        shop_type=shop.shop_type,
        distance_km=shop.distance_km,
        delivery_available=shop.delivery_available,
        product_count=product_count,
    )


# ── Stats ──────────────────────────────────────────────────────────

@app.get("/api/admin/stats", response_model=AdminStatsResponse)
def admin_stats(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    total_products = db.query(Product).count()
    total_shops = db.query(Shop).count()
    total_users = db.query(User).count()
    total_orders = db.query(CustomerOrder).count()
    pending_orders = db.query(CustomerOrder).filter(
        CustomerOrder.status.in_(["placed", "confirmed", "packed"])
    ).count()
    delivered_orders = db.query(CustomerOrder).filter(
        CustomerOrder.status == "delivered"
    ).count()

    delivered_shop_orders = db.query(ShopOrder).filter(ShopOrder.status == "delivered").all()
    total_revenue = 0.0
    for so in delivered_shop_orders:
        for item in so.items:
            total_revenue += item.price * item.quantity

    return AdminStatsResponse(
        total_products=total_products,
        total_shops=total_shops,
        total_users=total_users,
        total_orders=total_orders,
        total_revenue=round(total_revenue, 2),
        pending_orders=pending_orders,
        delivered_orders=delivered_orders,
    )


# ── Products ───────────────────────────────────────────────────────

@app.get("/api/admin/products", response_model=list[AdminProductResponse])
def admin_list_products(
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    query = db.query(Product)
    if shop_code:
        shop = db.query(Shop).filter(Shop.code == shop_code).first()
        if not shop:
            raise HTTPException(status_code=404, detail="Shop not found")
        query = query.filter(Product.shop_id == shop.id)
    products = query.order_by(Product.name).all()
    return [_product_to_admin_dto(p, db) for p in products]


@app.post("/api/admin/products", response_model=AdminProductResponse, status_code=201)
def admin_create_product(
    payload: AdminProductCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    shop = db.query(Shop).filter(Shop.code == payload.shop_code).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    existing = db.query(Product).filter(Product.code == payload.code).first()
    if existing:
        raise HTTPException(status_code=409, detail="Product code already exists")

    product = Product(
        code=payload.code,
        name=payload.name,
        subtitle=payload.subtitle,
        image=payload.image,
        price=payload.price,
        rating=payload.rating,
        review_count=payload.review_count,
        description=payload.description,
        stock=payload.stock,
        shop_id=shop.id,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_to_admin_dto(product, db)


@app.put("/api/admin/products/{product_code}", response_model=AdminProductResponse)
def admin_update_product(
    product_code: str,
    payload: AdminProductUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    product = db.query(Product).filter(Product.code == product_code).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    if payload.name is not None:
        product.name = payload.name
    if payload.subtitle is not None:
        product.subtitle = payload.subtitle
    if payload.image is not None:
        product.image = payload.image
    if payload.price is not None:
        product.price = payload.price
    if payload.rating is not None:
        product.rating = payload.rating
    if payload.review_count is not None:
        product.review_count = payload.review_count
    if payload.description is not None:
        product.description = payload.description
    if payload.stock is not None:
        product.stock = payload.stock

    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_to_admin_dto(product, db)


@app.patch("/api/admin/products/{product_code}/stock", response_model=AdminProductResponse)
def admin_update_stock(
    product_code: str,
    payload: AdminStockUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    product = db.query(Product).filter(Product.code == product_code).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    product.stock = payload.stock
    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_to_admin_dto(product, db)


@app.delete("/api/admin/products/{product_code}", status_code=204)
def admin_delete_product(
    product_code: str,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    product = db.query(Product).filter(Product.code == product_code).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    db.delete(product)
    db.commit()


# ── Shops ──────────────────────────────────────────────────────────

@app.get("/api/admin/shops", response_model=list[AdminShopResponse])
def admin_list_shops(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    shops = db.query(Shop).order_by(Shop.name).all()
    return [_shop_to_admin_dto(s, db) for s in shops]


@app.post("/api/admin/shops", response_model=AdminShopResponse, status_code=201)
def admin_create_shop(
    payload: AdminShopCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    existing = db.query(Shop).filter(Shop.code == payload.code).first()
    if existing:
        raise HTTPException(status_code=409, detail="Shop code already exists")

    shop = Shop(
        code=payload.code,
        name=payload.name,
        shop_type=payload.shop_type,
        distance_km=payload.distance_km,
        delivery_available=payload.delivery_available,
    )
    db.add(shop)
    db.commit()
    db.refresh(shop)
    return _shop_to_admin_dto(shop, db)


@app.put("/api/admin/shops/{shop_code}", response_model=AdminShopResponse)
def admin_update_shop(
    shop_code: str,
    payload: AdminShopUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    shop = db.query(Shop).filter(Shop.code == shop_code).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    if payload.name is not None:
        shop.name = payload.name
    if payload.shop_type is not None:
        shop.shop_type = payload.shop_type
    if payload.distance_km is not None:
        shop.distance_km = payload.distance_km
    if payload.delivery_available is not None:
        shop.delivery_available = payload.delivery_available

    db.add(shop)
    db.commit()
    db.refresh(shop)
    return _shop_to_admin_dto(shop, db)


@app.delete("/api/admin/shops/{shop_code}", status_code=204)
def admin_delete_shop(
    shop_code: str,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    shop = db.query(Shop).filter(Shop.code == shop_code).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")
    product_count = db.query(Product).filter(Product.shop_id == shop.id).count()
    if product_count > 0:
        raise HTTPException(
            status_code=409,
            detail=f"Cannot delete shop with {product_count} products. Delete products first.",
        )
    db.delete(shop)
    db.commit()


# ── Users ──────────────────────────────────────────────────────────

@app.get("/api/admin/users", response_model=list[AdminUserResponse])
def admin_list_users(
    role: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    query = db.query(User)
    if role:
        query = query.filter(User.role == role)
    users = query.order_by(User.created_at.desc()).all()
    return [
        AdminUserResponse(
            id=u.id,
            name=u.name,
            email=u.email,
            role=u.role,
            location=u.location,
            created_at=u.created_at,
        )
        for u in users
    ]


# ── Orders ──────────────────────────────────────────────────────────

@app.get("/api/admin/orders", response_model=list[AdminOrderResponse])
def admin_list_orders(
    status: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    query = db.query(CustomerOrder)
    if status:
        query = query.filter(CustomerOrder.status == status)
    orders = query.order_by(CustomerOrder.created_at.desc()).all()

    result = []
    for order in orders:
        total_items = 0
        grand_total = 0.0
        for so in order.shop_orders:
            for item in so.items:
                total_items += item.quantity
                grand_total += item.price * item.quantity
            grand_total += so.delivery_fee
        result.append(
            AdminOrderResponse(
                id=order.id,
                order_code=order.order_code,
                customer_user_id=order.customer_user_id,
                delivery_address=order.delivery_address,
                status=order.status,
                created_at=order.created_at,
                total_items=total_items,
                grand_total=round(grand_total, 2),
            )
        )
    return result


# ── Platform admin: create a shop admin account ────────────────

@app.post("/api/admin/shop-admins", response_model=AdminUserResponse, status_code=201)
def admin_create_shop_admin(
    payload: ShopAdminCreateRequest,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin_user),
):
    """Platform admin creates a shop_admin user linked to a specific shop."""
    shop = db.query(Shop).filter(Shop.code == payload.shop_code).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Shop not found")

    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=409, detail="Email already exists")

    user = User(
        name=payload.name,
        email=payload.email,
        password_hash=hash_password(payload.password),
        role="shop_admin",
        location="",
        managed_shop_id=shop.id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return AdminUserResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        role=user.role,
        location=user.location,
        created_at=user.created_at,
    )


# ════════════════════════════════════════════════════════════════
#  SHOP ADMIN ENDPOINTS  (/api/shop/*)
#  Accessible by: shop_admin (own shop only) or platform admin
# ════════════════════════════════════════════════════════════════

def _get_shop_for_user(current_user: User, db: Session, shop_code: str | None = None) -> Shop:
    """Return the shop a shop_admin manages, or look up by code if platform admin."""
    if current_user.role == "admin":
        if shop_code is None:
            raise HTTPException(status_code=400, detail="Platform admins must supply ?shop_code=")
        shop = db.query(Shop).filter(Shop.code == shop_code).first()
        if not shop:
            raise HTTPException(status_code=404, detail="Shop not found")
        return shop
    # shop_admin
    shop = db.query(Shop).filter(Shop.id == current_user.managed_shop_id).first()
    if not shop:
        raise HTTPException(status_code=404, detail="Managed shop not found")
    return shop


# ── Shop info & stats ─────────────────────────────────────────

@app.get("/api/shop/me", response_model=AdminShopResponse)
def shop_admin_get_shop(
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    """Return the shop details managed by the current shop admin."""
    shop = _get_shop_for_user(current_user, db, shop_code)
    return _shop_to_admin_dto(shop, db)


@app.get("/api/shop/stats", response_model=ShopAdminStatsResponse)
def shop_admin_stats(
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    shop = _get_shop_for_user(current_user, db, shop_code)

    total_products = db.query(Product).filter(Product.shop_id == shop.id).count()
    out_of_stock = db.query(Product).filter(Product.shop_id == shop.id, Product.stock == 0).count()

    shop_orders = db.query(ShopOrder).filter(ShopOrder.shop_id == shop.id).all()
    total_orders = len(shop_orders)
    pending_orders = sum(1 for so in shop_orders if so.status in ("placed", "confirmed", "packed"))
    ready_orders = sum(1 for so in shop_orders if so.status == "ready_for_pickup")
    delivered_orders = sum(1 for so in shop_orders if so.status == "delivered")

    total_revenue = 0.0
    for so in shop_orders:
        if so.status == "delivered":
            for item in so.items:
                total_revenue += item.price * item.quantity

    return ShopAdminStatsResponse(
        shop_id=shop.id,
        shop_code=shop.code,
        shop_name=shop.name,
        total_products=total_products,
        out_of_stock_products=out_of_stock,
        total_orders=total_orders,
        pending_orders=pending_orders,
        ready_orders=ready_orders,
        delivered_orders=delivered_orders,
        total_revenue=round(total_revenue, 2),
    )


# ── Products ──────────────────────────────────────────────────

@app.get("/api/shop/products", response_model=list[AdminProductResponse])
def shop_admin_list_products(
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    shop = _get_shop_for_user(current_user, db, shop_code)
    products = db.query(Product).filter(Product.shop_id == shop.id).order_by(Product.name).all()
    return [_product_to_admin_dto(p, db) for p in products]


@app.post("/api/shop/products", response_model=AdminProductResponse, status_code=201)
def shop_admin_create_product(
    payload: AdminProductCreate,
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    shop = _get_shop_for_user(current_user, db, shop_code)

    existing = db.query(Product).filter(Product.code == payload.code).first()
    if existing:
        raise HTTPException(status_code=409, detail="Product code already exists")

    product = Product(
        code=payload.code,
        name=payload.name,
        subtitle=payload.subtitle,
        image=payload.image,
        price=payload.price,
        rating=payload.rating,
        review_count=payload.review_count,
        description=payload.description,
        stock=payload.stock,
        shop_id=shop.id,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_to_admin_dto(product, db)


@app.put("/api/shop/products/{product_code}", response_model=AdminProductResponse)
def shop_admin_update_product(
    product_code: str,
    payload: AdminProductUpdate,
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    shop = _get_shop_for_user(current_user, db, shop_code)
    product = db.query(Product).filter(Product.code == product_code, Product.shop_id == shop.id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found in your shop")

    if payload.name is not None:
        product.name = payload.name
    if payload.subtitle is not None:
        product.subtitle = payload.subtitle
    if payload.image is not None:
        product.image = payload.image
    if payload.price is not None:
        product.price = payload.price
    if payload.rating is not None:
        product.rating = payload.rating
    if payload.review_count is not None:
        product.review_count = payload.review_count
    if payload.description is not None:
        product.description = payload.description
    if payload.stock is not None:
        product.stock = payload.stock

    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_to_admin_dto(product, db)


@app.patch("/api/shop/products/{product_code}/stock", response_model=AdminProductResponse)
def shop_admin_update_stock(
    product_code: str,
    payload: AdminStockUpdate,
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    shop = _get_shop_for_user(current_user, db, shop_code)
    product = db.query(Product).filter(Product.code == product_code, Product.shop_id == shop.id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found in your shop")

    product.stock = payload.stock
    db.add(product)
    db.commit()
    db.refresh(product)
    return _product_to_admin_dto(product, db)


@app.delete("/api/shop/products/{product_code}", status_code=204)
def shop_admin_delete_product(
    product_code: str,
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    shop = _get_shop_for_user(current_user, db, shop_code)
    product = db.query(Product).filter(Product.code == product_code, Product.shop_id == shop.id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found in your shop")
    db.delete(product)
    db.commit()


# ── Orders / Delivery monitoring ─────────────────────────────

def _build_shop_order_response(db: Session, so: ShopOrder) -> ShopAdminOrderResponse:
    customer_order = db.query(CustomerOrder).filter(CustomerOrder.id == so.customer_order_id).first()
    customer = db.query(User).filter(User.id == customer_order.customer_user_id).first() if customer_order else None

    items: list[ShopAdminOrderItemResponse] = []
    items_total = 0.0
    for item in so.items:
        product = db.query(Product).filter(Product.id == item.product_id).first()
        items.append(ShopAdminOrderItemResponse(
            product_id=product.code if product else str(item.product_id),
            product_name=product.name if product else "Unknown",
            quantity=item.quantity,
            price=item.price,
        ))
        items_total += item.price * item.quantity

    return ShopAdminOrderResponse(
        id=so.id,
        shop_order_code=so.shop_order_code,
        customer_order_id=so.customer_order_id,
        customer_name=customer.name if customer else "Unknown",
        delivery_address=customer_order.delivery_address if customer_order else "",
        status=so.status,
        delivery_job_status=so.delivery_job_status,
        selected_delivery_type=so.selected_delivery_type,
        delivery_fee=so.delivery_fee,
        eta_minutes=so.eta_minutes,
        created_at=customer_order.created_at if customer_order else datetime.utcnow(),
        items=items,
        items_total=round(items_total, 2),
        assigned_delivery_name=so.assigned_delivery_name,
    )


@app.get("/api/shop/orders", response_model=list[ShopAdminOrderResponse])
def shop_admin_list_orders(
    status: str | None = None,
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    """List all orders for the shop. Optionally filter by status."""
    shop = _get_shop_for_user(current_user, db, shop_code)
    query = db.query(ShopOrder).filter(ShopOrder.shop_id == shop.id)
    if status:
        query = query.filter(ShopOrder.status == status)
    orders = query.order_by(ShopOrder.id.desc()).all()
    return [_build_shop_order_response(db, so) for so in orders]


@app.post("/api/shop/orders/{shop_order_code}/status", response_model=ShopAdminOrderResponse)
def shop_admin_update_order_status(
    shop_order_code: str,
    payload: ShopAdminOrderStatusUpdate,
    shop_code: str | None = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_shop_admin),
):
    """
    Shop admin can transition orders:
      confirmed → packed → ready_for_pickup  (for home_delivery: confirmed → packed → available for delivery)
      Or cancel (if not yet out_for_delivery/delivered).
    """
    shop = _get_shop_for_user(current_user, db, shop_code)
    so = db.query(ShopOrder).filter(
        ShopOrder.shop_order_code == shop_order_code,
        ShopOrder.shop_id == shop.id,
    ).first()
    if not so:
        raise HTTPException(status_code=404, detail="Order not found in your shop")

    if so.status in ("out_for_delivery", "delivered", "cancelled"):
        raise HTTPException(status_code=409, detail=f"Cannot update order in '{so.status}' status")

    new_status = payload.status

    # If cancelling, also propagate delivery job cancellation
    if new_status == "cancelled":
        so.status = "cancelled"
        so.delivery_job_status = "cancelled"
    elif new_status == "ready_for_pickup":
        # Shop is ready; mark delivery job as available so delivery person can pick it up
        so.status = "packed"
        so.delivery_job_status = "available"
    else:
        so.status = new_status

    db.add(so)
    db.commit()
    db.refresh(so)
    return _build_shop_order_response(db, so)
    return result
