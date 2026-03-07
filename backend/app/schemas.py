from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class HealthResponse(BaseModel):
    status: str


class AuthSignupRequest(BaseModel):
    name: str = Field(min_length=2)
    email: EmailStr
    password: str = Field(min_length=6)
    role: str = Field(pattern="^(customer|delivery_person)$")


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
