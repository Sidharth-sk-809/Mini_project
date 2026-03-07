from datetime import datetime

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from .auth import (
    create_access_token,
    get_current_user,
    hash_password,
    require_delivery_user,
    verify_password,
)
from .database import Base, SessionLocal, engine, get_db
from .models import CustomerOrder, Product, Shop, ShopOrder, ShopOrderItem, User
from .schemas import (
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
