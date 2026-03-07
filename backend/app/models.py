from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(40), default="customer")
    location: Mapped[str] = mapped_column(String(255), default="Edappally, Kochi")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


class Shop(Base):
    __tablename__ = "shops"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120))
    shop_type: Mapped[str] = mapped_column(String(80))
    distance_km: Mapped[int] = mapped_column(Integer)
    delivery_available: Mapped[bool] = mapped_column(Boolean, default=True)

    products: Mapped[list["Product"]] = relationship(back_populates="shop")


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(120), index=True)
    subtitle: Mapped[str] = mapped_column(String(80))
    image: Mapped[str] = mapped_column(String(255))
    price: Mapped[float] = mapped_column(Float)
    rating: Mapped[float] = mapped_column(Float, default=4.5)
    review_count: Mapped[int] = mapped_column(Integer, default=20)
    description: Mapped[str] = mapped_column(Text)
    stock: Mapped[int] = mapped_column(Integer, default=10)

    shop_id: Mapped[int] = mapped_column(ForeignKey("shops.id"), index=True)
    shop: Mapped[Shop] = relationship(back_populates="products")


class CustomerOrder(Base):
    __tablename__ = "customer_orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    order_code: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    customer_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    delivery_address: Mapped[str] = mapped_column(String(255))
    status: Mapped[str] = mapped_column(String(40), default="placed")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    shop_orders: Mapped[list["ShopOrder"]] = relationship(back_populates="customer_order")


class ShopOrder(Base):
    __tablename__ = "shop_orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    shop_order_code: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    customer_order_id: Mapped[int] = mapped_column(ForeignKey("customer_orders.id"), index=True)
    shop_id: Mapped[int] = mapped_column(ForeignKey("shops.id"), index=True)

    status: Mapped[str] = mapped_column(String(40), default="placed")
    delivery_job_status: Mapped[str] = mapped_column(String(40), default="available")
    selected_delivery_type: Mapped[str] = mapped_column(String(30), default="home_delivery")
    delivery_fee: Mapped[float] = mapped_column(Float, default=0)
    eta_minutes: Mapped[int] = mapped_column(Integer, default=30)
    assigned_delivery_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    assigned_delivery_name: Mapped[str | None] = mapped_column(String(120), nullable=True)

    customer_order: Mapped[CustomerOrder] = relationship(back_populates="shop_orders")
    items: Mapped[list["ShopOrderItem"]] = relationship(back_populates="shop_order")


class ShopOrderItem(Base):
    __tablename__ = "shop_order_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    shop_order_id: Mapped[int] = mapped_column(ForeignKey("shop_orders.id"), index=True)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), index=True)
    quantity: Mapped[int] = mapped_column(Integer, default=1)
    price: Mapped[float] = mapped_column(Float)

    shop_order: Mapped[ShopOrder] = relationship(back_populates="items")
