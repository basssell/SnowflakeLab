from __future__ import annotations

import csv
import json
import random
from datetime import datetime, timedelta
from pathlib import Path


SEED = 42
BASE_DIR = Path(__file__).resolve().parents[1]
OUTPUT_DIR = BASE_DIR / "data" / "generated"


FIRST_NAMES = [
    "Camille",
    "Louis",
    "Lea",
    "Hugo",
    "Ines",
    "Lucas",
    "Manon",
    "Nathan",
    "Chloe",
    "Adam",
    "Sarah",
    "Mehdi",
    "Nina",
    "Antoine",
    "Yasmine",
    "Jules",
]

LAST_NAMES = [
    "Martin",
    "Bernard",
    "Dubois",
    "Thomas",
    "Robert",
    "Richard",
    "Petit",
    "Durand",
    "Leroy",
    "Moreau",
    "Simon",
    "Laurent",
    "Lefebvre",
    "Michel",
]

CITIES = [
    "Paris",
    "Lyon",
    "Marseille",
    "Toulouse",
    "Bordeaux",
    "Lille",
    "Nantes",
    "Strasbourg",
    "Montpellier",
    "Rennes",
]

SEGMENTS = [
    "Student",
    "Young Professional",
    "Family",
    "Premium",
    "Small Business",
]

CATEGORIES = {
    "Electronics": ["Nova", "PixelCraft", "Voltix"],
    "Home": ["Maisonix", "CasaBelle", "North Home"],
    "Beauty": ["Lumiere", "PureSkin", "BelleVie"],
    "Sports": ["RunWell", "AltiFit", "UrbanMove"],
    "Books": ["PaperTrail", "InkHouse", "Readly"],
    "Grocery": ["FreshCo", "DailyFarm", "BioPanier"],
}

PRODUCT_NAMES = {
    "Electronics": ["Bluetooth Speaker", "USB-C Hub", "Wireless Mouse", "Desk Lamp", "Noise-Canceling Earbuds"],
    "Home": ["Cotton Towel Set", "Storage Basket", "Ceramic Mug", "Kitchen Scale", "Scented Candle"],
    "Beauty": ["Hydrating Cream", "Face Cleanser", "Shampoo Bar", "Body Lotion", "Lip Balm Set"],
    "Sports": ["Yoga Mat", "Running Bottle", "Resistance Bands", "Gym Towel", "Training Socks"],
    "Books": ["Data Basics Guide", "French Cooking Notes", "Travel Journal", "SQL Pocket Book", "Design Thinking Workbook"],
    "Grocery": ["Organic Coffee", "Almond Granola", "Olive Oil", "Dark Chocolate", "Herbal Tea"],
}

STATUSES = ["delivered", "shipped", "processing", "cancelled", "returned"]
PAYMENT_METHODS = ["card", "paypal", "bank_transfer"]
EVENT_TYPES = ["page_view", "product_view", "add_to_cart", "checkout_started", "purchase", "search"]
DEVICES = ["mobile", "desktop", "tablet"]
UTM_SOURCES = ["google", "newsletter", "instagram", "direct", "partner"]


def random_date(start: datetime, end: datetime) -> datetime:
    delta = end - start
    return start + timedelta(seconds=random.randint(0, int(delta.total_seconds())))


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def make_customers() -> list[dict[str, object]]:
    customers = []
    for i in range(1, 101):
        first_name = random.choice(FIRST_NAMES)
        last_name = random.choice(LAST_NAMES)
        email = f"{first_name}.{last_name}.{i}@example.fr".lower()

        # Intentional issue for the data quality phase.
        if i == 7:
            email = "invalid-email"

        customers.append(
            {
                "customer_id": f"C{i:04d}",
                "first_name": first_name,
                "last_name": last_name,
                "email": email,
                "city": random.choice(CITIES),
                "country": "FR",
                "segment": random.choice(SEGMENTS),
                "signup_date": random_date(datetime(2023, 1, 1), datetime(2025, 12, 31)).date().isoformat(),
                "marketing_opt_in": random.choice([True, False]),
            }
        )
    return customers


def make_products() -> list[dict[str, object]]:
    products = []
    for i in range(1, 51):
        category = random.choice(list(CATEGORIES))
        brand = random.choice(CATEGORIES[category])
        name = random.choice(PRODUCT_NAMES[category])
        price = round(random.uniform(4.5, 180.0), 2)
        products.append(
            {
                "product_id": f"P{i:04d}",
                "sku": f"{category[:3].upper()}-{i:04d}",
                "product_name": f"{brand} {name}",
                "category": category,
                "brand": brand,
                "unit_price": price,
                "active_flag": random.choice([True, True, True, False]),
            }
        )
    return products


def make_orders(customers: list[dict[str, object]]) -> list[dict[str, object]]:
    orders = []
    start = datetime(2026, 1, 1)
    end = datetime(2026, 3, 31)
    orphan_order_ids = {"O000021", "O000177", "O000315"}
    high_discount_order_ids = {"O000010", "O000245"}

    for i in range(1, 501):
        order_id = f"O{i:06d}"
        customer_id = random.choice(customers)["customer_id"]
        if order_id in orphan_order_ids:
            customer_id = "C9999"

        discount_amount = round(random.choice([0, 0, 0, 5, 10, 15, 20]) * random.random(), 2)
        if order_id in high_discount_order_ids:
            discount_amount = 999.0

        orders.append(
            {
                "order_id": order_id,
                "customer_id": customer_id,
                "order_date": random_date(start, end).date().isoformat(),
                "status": random.choices(STATUSES, weights=[65, 15, 12, 5, 3])[0],
                "payment_method": random.choice(PAYMENT_METHODS),
                "shipping_city": random.choice(CITIES),
                "discount_amount": discount_amount,
            }
        )
    return orders


def make_order_items(orders: list[dict[str, object]], products: list[dict[str, object]]) -> list[dict[str, object]]:
    items = []
    no_item_orders = {"O000099", "O000222", "O000401"}
    eligible_orders = [order for order in orders if order["order_id"] not in no_item_orders]
    product_by_id = {product["product_id"]: product for product in products}

    def make_item(order: dict[str, object], item_number: int) -> dict[str, object]:
        product = random.choice(products)
        product_id = product["product_id"]
        quantity = random.randint(1, 4)
        unit_price = product["unit_price"]

        # A few intentional issues for the data quality phase.
        if item_number in {25, 640, 930}:
            product_id = "P9999"
            unit_price = 19.99
        if item_number in {88, 777}:
            quantity = 0

        return {
            "order_item_id": f"OI{item_number:07d}",
            "order_id": order["order_id"],
            "product_id": product_id,
            "quantity": quantity,
            "unit_price": product_by_id.get(product_id, {"unit_price": unit_price})["unit_price"],
        }

    item_number = 1
    for order in eligible_orders:
        items.append(make_item(order, item_number))
        item_number += 1

    while len(items) < 1200:
        order = random.choice(eligible_orders)
        items.append(make_item(order, item_number))
        item_number += 1

    return items


def make_events(
    customers: list[dict[str, object]],
    products: list[dict[str, object]],
    orders: list[dict[str, object]],
) -> list[dict[str, object]]:
    events = []
    start = datetime(2026, 1, 1)
    end = datetime(2026, 3, 31, 23, 59, 59)

    for i in range(1, 501):
        event_type = random.choices(EVENT_TYPES, weights=[30, 28, 16, 10, 8, 8])[0]
        customer = random.choice(customers)
        product = random.choice(products)
        order = random.choice(orders)
        event_time = random_date(start, end)

        items = []
        if event_type in {"add_to_cart", "checkout_started", "purchase"}:
            for _ in range(random.randint(1, 3)):
                item_product = random.choice(products)
                items.append(
                    {
                        "product_id": item_product["product_id"],
                        "quantity": random.randint(1, 3),
                        "unit_price": item_product["unit_price"],
                    }
                )

        events.append(
            {
                "event_id": f"E{i:06d}",
                "event_timestamp": event_time.isoformat(timespec="seconds"),
                "customer_id": customer["customer_id"],
                "session_id": f"S{random.randint(1, 180):05d}",
                "event_type": event_type,
                "page": random.choice(["home", "product", "cart", "checkout", "search", "account"]),
                "product_id": product["product_id"] if event_type in {"product_view", "add_to_cart"} else None,
                "order_id": order["order_id"] if event_type == "purchase" else None,
                "device": random.choice(DEVICES),
                "context": {
                    "utm_source": random.choice(UTM_SOURCES),
                    "campaign": random.choice(["winter_sale", "new_customer", "loyalty", "none"]),
                    "language": "fr",
                },
                "items": items,
            }
        )

    return events


def make_incremental_orders(customers: list[dict[str, object]], products: list[dict[str, object]]) -> tuple[list[dict[str, object]], list[dict[str, object]]]:
    orders = []
    items = []
    start = datetime(2026, 4, 1)
    end = datetime(2026, 4, 7)
    item_number = 1201

    for i in range(501, 521):
        order = {
            "order_id": f"O{i:06d}",
            "customer_id": random.choice(customers)["customer_id"],
            "order_date": random_date(start, end).date().isoformat(),
            "status": random.choices(STATUSES, weights=[70, 18, 8, 2, 2])[0],
            "payment_method": random.choice(PAYMENT_METHODS),
            "shipping_city": random.choice(CITIES),
            "discount_amount": round(random.choice([0, 0, 5, 10]) * random.random(), 2),
        }
        orders.append(order)

        item_count = 3 if i < 511 else 2
        for _ in range(item_count):
            product = random.choice(products)
            items.append(
                {
                    "order_item_id": f"OI{item_number:07d}",
                    "order_id": order["order_id"],
                    "product_id": product["product_id"],
                    "quantity": random.randint(1, 4),
                    "unit_price": product["unit_price"],
                }
            )
            item_number += 1

    return orders, items[:50]


def main() -> None:
    random.seed(SEED)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    customers = make_customers()
    products = make_products()
    orders = make_orders(customers)
    order_items = make_order_items(orders, products)
    events = make_events(customers, products, orders)
    incremental_orders, incremental_items = make_incremental_orders(customers, products)

    write_csv(
        OUTPUT_DIR / "customers.csv",
        customers,
        ["customer_id", "first_name", "last_name", "email", "city", "country", "segment", "signup_date", "marketing_opt_in"],
    )
    write_csv(
        OUTPUT_DIR / "products.csv",
        products,
        ["product_id", "sku", "product_name", "category", "brand", "unit_price", "active_flag"],
    )
    write_csv(
        OUTPUT_DIR / "orders.csv",
        orders,
        ["order_id", "customer_id", "order_date", "status", "payment_method", "shipping_city", "discount_amount"],
    )
    write_csv(
        OUTPUT_DIR / "order_items.csv",
        order_items,
        ["order_item_id", "order_id", "product_id", "quantity", "unit_price"],
    )
    write_csv(
        OUTPUT_DIR / "orders_incremental.csv",
        incremental_orders,
        ["order_id", "customer_id", "order_date", "status", "payment_method", "shipping_city", "discount_amount"],
    )
    write_csv(
        OUTPUT_DIR / "order_items_incremental.csv",
        incremental_items,
        ["order_item_id", "order_id", "product_id", "quantity", "unit_price"],
    )

    with (OUTPUT_DIR / "events.json").open("w", encoding="utf-8") as handle:
        for event in events:
            handle.write(json.dumps(event, ensure_ascii=False) + "\n")

    print("Generated files in", OUTPUT_DIR)
    print("customers.csv: 100 rows")
    print("products.csv: 50 rows")
    print("orders.csv: 500 rows")
    print("order_items.csv: 1200 rows")
    print("events.json: 500 JSON lines")
    print("orders_incremental.csv: 20 rows")
    print("order_items_incremental.csv: 50 rows")


if __name__ == "__main__":
    main()
