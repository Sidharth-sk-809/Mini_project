from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class HealthResponse(BaseModel):
    status: str


class AuthSignupRequest(BaseModel):
    name: str = Field(min_length=2)
    email: EmailStr
    password: str = Field(min_length=6)
    role: str = Field(pattern="^(customer|delivery_person|admin)$")


class AuthLoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    name: str
    email: EmailStr
    role: str
    location: str


class LocationUpdateRequest(BaseModel):
    location: str = Field(min_length=2)


class ShopDTO(BaseModel):
    id: str
    name: str
    type: str
    distance_km: int
    delivery_available: bool
    product_names: list[str]


class ProductDTO(BaseModel):
    id: str
    name: str
    subtitle: str
    price: float
    image: str
    rating: float
    review_count: int
    seller: str
    vendor: str
    description: str
    shop_id: str
    stock: int
    shop_distance_km: float
    delivery_available: bool
    shop_type: str


class CatalogBootstrapResponse(BaseModel):
    categories: list[str]
    ranges_km: list[int]
    shops: list[ShopDTO]
    products: list[ProductDTO]


class SearchResponse(BaseModel):
    query: str
    query_type: str
    products: list[ProductDTO]
    shops: list[ShopDTO]


class CreateOrderItem(BaseModel):
    product_id: str
    quantity: int = Field(ge=1)


class CreateShopOrder(BaseModel):
    shop_id: str
    delivery_type: str = Field(pattern="^(home_delivery|shop_pickup)$")
    items: list[CreateOrderItem]


class CreateOrderRequest(BaseModel):
    delivery_address: str
    shop_orders: list[CreateShopOrder]


class ShopOrderItemDTO(BaseModel):
    product_id: str
    product_name: str
    image: str
    subtitle: str
    quantity: int
    price: float


class ShopOrderDTO(BaseModel):
    id: str
    shop_id: str
    shop_name: str
    status: str
    delivery_job_status: str
    selected_delivery_type: str
    delivery_fee: float
    eta_minutes: int
    items_total: float
    items: list[ShopOrderItemDTO]
    assigned_delivery_user_id: int | None = None
    assigned_delivery_name: str | None = None


class OrderDTO(BaseModel):
    id: str
    delivery_address: str
    status: str
    created_at: datetime
    shop_orders: list[ShopOrderDTO]


class DeliveryStatusUpdateRequest(BaseModel):
    status: str = Field(pattern="^(accepted|picked_up|delivered)$")


# ── Admin Schemas ────────────────────────────────────────────────

class AdminProductCreate(BaseModel):
    shop_code: str
    code: str = Field(min_length=2)
    name: str = Field(min_length=2)
    subtitle: str = ""
    image: str = ""
    price: float = Field(gt=0)
    rating: float = Field(default=4.5, ge=0, le=5)
    review_count: int = Field(default=0, ge=0)
    description: str = ""
    stock: int = Field(default=10, ge=0)


class AdminProductUpdate(BaseModel):
    name: str | None = None
    subtitle: str | None = None
    image: str | None = None
    price: float | None = Field(default=None, gt=0)
    rating: float | None = Field(default=None, ge=0, le=5)
    review_count: int | None = Field(default=None, ge=0)
    description: str | None = None
    stock: int | None = Field(default=None, ge=0)


class AdminStockUpdate(BaseModel):
    stock: int = Field(ge=0)


class AdminShopCreate(BaseModel):
    code: str = Field(min_length=2)
    name: str = Field(min_length=2)
    shop_type: str = ""
    distance_km: int = Field(default=5, ge=0)
    delivery_available: bool = True


class AdminShopUpdate(BaseModel):
    name: str | None = None
    shop_type: str | None = None
    distance_km: int | None = Field(default=None, ge=0)
    delivery_available: bool | None = None


class AdminProductResponse(BaseModel):
    id: int
    code: str
    name: str
    subtitle: str
    image: str
    price: float
    rating: float
    review_count: int
    description: str
    stock: int
    shop_id: int
    shop_code: str
    shop_name: str


class AdminShopResponse(BaseModel):
    id: int
    code: str
    name: str
    shop_type: str
    distance_km: int
    delivery_available: bool
    product_count: int


class AdminUserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    location: str
    created_at: datetime


class AdminOrderResponse(BaseModel):
    id: int
    order_code: str
    customer_user_id: int
    delivery_address: str
    status: str
    created_at: datetime
    total_items: int
    grand_total: float


class AdminStatsResponse(BaseModel):
    total_products: int
    total_shops: int
    total_users: int
    total_orders: int
    total_revenue: float
    pending_orders: int
    delivered_orders: int


# ── Shop Admin Schemas ───────────────────────────────────────────

class ShopAdminCreateRequest(BaseModel):
    """Platform admin creates a shop_admin account and links it to a shop."""
    name: str = Field(min_length=2)
    email: EmailStr
    password: str = Field(min_length=6)
    shop_code: str = Field(min_length=2)


class ShopAdminOrderStatusUpdate(BaseModel):
    """Shop admin can move an order through: confirmed → packed → ready_for_pickup, or cancel."""
    status: str = Field(pattern="^(confirmed|packed|ready_for_pickup|cancelled)$")


class ShopAdminStatsResponse(BaseModel):
    shop_id: int
    shop_code: str
    shop_name: str
    total_products: int
    out_of_stock_products: int
    total_orders: int
    pending_orders: int
    ready_orders: int
    delivered_orders: int
    total_revenue: float


class ShopAdminOrderItemResponse(BaseModel):
    product_id: str
    product_name: str
    quantity: int
    price: float


class ShopAdminOrderResponse(BaseModel):
    id: int
    shop_order_code: str
    customer_order_id: int
    customer_name: str
    delivery_address: str
    status: str
    delivery_job_status: str
    selected_delivery_type: str
    delivery_fee: float
    eta_minutes: int
    created_at: datetime
    items: list[ShopAdminOrderItemResponse]
    items_total: float
    assigned_delivery_name: str | None = None
