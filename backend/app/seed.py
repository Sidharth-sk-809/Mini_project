from datetime import datetime

from sqlalchemy.orm import Session

from .auth import hash_password
from .models import CustomerOrder, Product, Shop, ShopOrder, ShopOrderItem, User

CATEGORIES = ["All", "Stationary", "Fruits", "Medicine", "Vegetables"]
RANGES_KM = [2, 5, 10]

ASSET_BY_PRODUCT_NAME = {
    "Potato": "assets/products/Potato.png",
    "Tomato": "assets/products/Tomato.png",
    "Carrot": "assets/products/Carrot.png",
    "Cabbage": "assets/products/Cabbage.png",
    "Pen": "assets/products/Pen.png",
    "Pencil": "assets/products/Pencil.png",
    "Book": "assets/products/Notebook.png",
    "Hammer": "assets/products/Hammer.png",
    "Paracetamol": "assets/products/Paracetamol.png",
    "Cough Syrup": "assets/products/Cough Syrup.png",
    "Bandage": "assets/products/Bandage.png",
    "Pipe": "assets/products/Pipe.png",
    "Tap": "assets/products/Tap.png",
    "Wrench": "assets/products/Wrench.png",
    "Bread": "assets/products/Bread.png",
    "Bun": "assets/products/Bun.png",
    "Cake": "assets/products/Cake.png",
    "Paper": "assets/products/Paper.png",
    "Scale": "assets/products/Scale.png",
}

BASE_PRICE = {
    "Potato": 42,
    "Tomato": 58,
    "Carrot": 70,
    "Cabbage": 48,
    "Pen": 15,
    "Pencil": 12,
    "Book": 38,
    "Paper": 22,
    "Scale": 18,
    "Hammer": 260,
    "Pipe": 220,
    "Tap": 180,
    "Wrench": 210,
    "Paracetamol": 45,
    "Cough Syrup": 95,
    "Bandage": 30,
    "Bread": 35,
    "Bun": 28,
    "Cake": 180,
}

SHOP_MULTIPLIER = {
    "green_basket": 1.00,
    "paper_point": 1.00,
    "fresh_farm_market": 1.08,
    "study_world": 1.06,
    "medico_hub": 1.12,
    "city_veggies": 1.15,
    "smart_stationers": 1.14,
    "pipemaster_tools": 1.20,
    "bake_house_delight": 1.09,
}

SHOP_DATA = [
    {
        "code": "green_basket",
        "name": "Green Basket",
        "shop_type": "Vegetable Shop",
        "distance_km": 2,
        "delivery_available": True,
        "product_names": ["Potato", "Tomato", "Carrot", "Cabbage"],
    },
    {
        "code": "paper_point",
        "name": "Paper Point",
        "shop_type": "Stationary Shop",
        "distance_km": 2,
        "delivery_available": True,
        "product_names": ["Scale", "Book", "Pen", "Paper", "Pencil"],
    },
    {
        "code": "fresh_farm_market",
        "name": "Fresh Farm Market",
        "shop_type": "Vegetable Shop",
        "distance_km": 5,
        "delivery_available": True,
        "product_names": ["Potato", "Tomato", "Carrot", "Cabbage"],
    },
    {
        "code": "study_world",
        "name": "Study World",
        "shop_type": "Stationary Shop",
        "distance_km": 5,
        "delivery_available": True,
        "product_names": ["Scale", "Book", "Pen", "Paper", "Pencil"],
    },
    {
        "code": "medico_hub",
        "name": "Medico Hub",
        "shop_type": "Medicine Shop",
        "distance_km": 5,
        "delivery_available": True,
        "product_names": ["Paracetamol", "Cough Syrup", "Bandage"],
    },
    {
        "code": "city_veggies",
        "name": "City Veggies",
        "shop_type": "Vegetable Shop",
        "distance_km": 10,
        "delivery_available": False,
        "product_names": ["Potato", "Tomato", "Carrot", "Cabbage"],
    },
    {
        "code": "smart_stationers",
        "name": "Smart Stationers",
        "shop_type": "Stationary Shop",
        "distance_km": 10,
        "delivery_available": False,
        "product_names": ["Scale", "Book", "Pen", "Paper", "Pencil"],
    },
    {
        "code": "pipemaster_tools",
        "name": "PipeMaster Tools",
        "shop_type": "Plumbing Tools",
        "distance_km": 10,
        "delivery_available": False,
        "product_names": ["Pipe", "Tap", "Wrench", "Hammer"],
    },
    {
        "code": "bake_house_delight",
        "name": "Bake House Delight",
        "shop_type": "Bakery",
        "distance_km": 10,
        "delivery_available": True,
        "product_names": ["Bread", "Bun", "Cake"],
    },
]


def seed_data(db: Session):
    if db.query(Shop).count() > 0:
        return

    for shop_data in SHOP_DATA:
        shop = Shop(
            code=shop_data["code"],
            name=shop_data["name"],
            shop_type=shop_data["shop_type"],
            distance_km=shop_data["distance_km"],
            delivery_available=shop_data["delivery_available"],
        )
        db.add(shop)
        db.flush()

        for idx, product_name in enumerate(shop_data["product_names"]):
            image = ASSET_BY_PRODUCT_NAME.get(product_name)
            if not image:
                continue

            base_price = BASE_PRICE.get(product_name, 50)
            multiplier = SHOP_MULTIPLIER.get(shop.code, 1.0)
            final_price = float(round(base_price * multiplier))

            db.add(
                Product(
                    code=f"{shop.code}_{idx}_{product_name.lower().replace(' ', '_')}",
                    name=product_name,
                    subtitle=shop.shop_type,
                    image=image,
                    price=final_price,
                    rating=4.0 + ((idx % 7) / 10),
                    review_count=25 + idx * 8,
                    description=f"{product_name} from {shop.name}",
                    stock=8 + (idx % 12),
                    shop_id=shop.id,
                )
            )

    if db.query(User).count() == 0:
        db.add(
            User(
                name="Customer Demo",
                email="customer@neamet.app",
                password_hash=hash_password("password123"),
                role="customer",
                location="Edappally, Kochi",
            )
        )
        db.add(
            User(
                name="Delivery Demo",
                email="delivery@neamet.app",
                password_hash=hash_password("password123"),
                role="delivery_person",
                location="Edappally, Kochi",
            )
        )
        db.add(
            User(
                name="Admin",
                email="admin@neamet.app",
                password_hash=hash_password("admin123"),
                role="admin",
                location="Edappally, Kochi",
            )
        )

    db.commit()


def seed_demo_orders(db: Session):
    if db.query(CustomerOrder).count() > 0:
        return

    customer = db.query(User).filter(User.role == "customer").first()
    delivery_user = db.query(User).filter(User.role == "delivery_person").first()
    if not customer:
        return

    green_basket = db.query(Shop).filter(Shop.code == "green_basket").first()
    paper_point = db.query(Shop).filter(Shop.code == "paper_point").first()
    if not green_basket or not paper_point:
        return

    potato = (
        db.query(Product)
        .filter(Product.shop_id == green_basket.id, Product.name == "Potato")
        .first()
    )
    tomato = (
        db.query(Product)
        .filter(Product.shop_id == green_basket.id, Product.name == "Tomato")
        .first()
    )
    book = (
        db.query(Product)
        .filter(Product.shop_id == paper_point.id, Product.name == "Book")
        .first()
    )

    if not potato or not tomato or not book:
        return

    now = datetime.utcnow()

    order = CustomerOrder(
        order_code=f"ORD-DEMO-{int(now.timestamp())}",
        customer_user_id=customer.id,
        delivery_address=customer.location,
        status="confirmed",
        created_at=now,
    )
    db.add(order)
    db.flush()

    so1 = ShopOrder(
        shop_order_code=f"SO-DEMO-{int(now.timestamp())}-0",
        customer_order_id=order.id,
        shop_id=green_basket.id,
        status="confirmed",
        delivery_job_status="available",
        selected_delivery_type="home_delivery",
        delivery_fee=26,
        eta_minutes=32,
    )
    db.add(so1)
    db.flush()
    db.add(ShopOrderItem(shop_order_id=so1.id, product_id=potato.id, quantity=1, price=potato.price))
    db.add(ShopOrderItem(shop_order_id=so1.id, product_id=tomato.id, quantity=1, price=tomato.price))

    so2 = ShopOrder(
        shop_order_code=f"SO-DEMO-DONE-{int(now.timestamp())}-1",
        customer_order_id=order.id,
        shop_id=paper_point.id,
        status="delivered",
        delivery_job_status="delivered",
        selected_delivery_type="home_delivery",
        delivery_fee=20,
        eta_minutes=26,
        assigned_delivery_user_id=delivery_user.id if delivery_user else None,
        assigned_delivery_name=delivery_user.name if delivery_user else "Delivery Demo",
    )
    db.add(so2)
    db.flush()
    db.add(ShopOrderItem(shop_order_id=so2.id, product_id=book.id, quantity=1, price=book.price))

    db.commit()
