from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

from fastapi import HTTPException, status
from sqlalchemy import Date, Float, Integer, and_, case, cast, func, or_, select
from sqlalchemy.orm import Session

from app.models import Inventory, Product, Sale, SaleItem, User


BANGKOK = ZoneInfo("Asia/Bangkok")


def normalize_range(start: datetime, end: datetime) -> tuple[datetime, datetime]:
    def as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            value = value.replace(tzinfo=BANGKOK)
        return value.astimezone(timezone.utc)

    start_utc = as_utc(start)
    end_utc = as_utc(end)
    if start_utc > end_utc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "invalid_date_range",
                "message": "The start date must not be after the end date.",
            },
        )
    return start_utc, end_utc


def today_range() -> tuple[datetime, datetime]:
    today = datetime.now(timezone.utc).astimezone(BANGKOK).date()
    start_local = datetime.combine(today, time.min, tzinfo=BANGKOK)
    end_local = datetime.combine(today + timedelta(days=1), time.min, tzinfo=BANGKOK)
    return (
        start_local.astimezone(timezone.utc),
        (end_local - timedelta(microseconds=1)).astimezone(timezone.utc),
    )


def _sale_filters(
    user: User, start: datetime, end: datetime
) -> tuple:
    start_utc, end_utc = normalize_range(start, end)
    return (
        Sale.user_id == user.id,
        Sale.sale_date >= start_utc,
        Sale.sale_date <= end_utc,
    )


def sales_in_range(
    db: Session, user: User, start: datetime, end: datetime
) -> list[Sale]:
    return list(
        db.scalars(
            select(Sale)
            .where(*_sale_filters(user, start, end))
            .order_by(Sale.sale_date.desc(), Sale.id.desc())
        )
    )


def sales_by_hour(
    db: Session, user: User, start: datetime, end: datetime
) -> dict:
    local_sale_time = func.timezone("Asia/Bangkok", Sale.sale_date)
    hour = cast(func.extract("hour", local_sale_time), Integer)
    rows = db.execute(
        select(
            hour.label("hour"),
            func.count(Sale.id).label("transaction_count"),
            func.sum(Sale.total_amount).label("total_revenue"),
        )
        .where(*_sale_filters(user, start, end))
        .group_by(hour)
        .order_by(hour)
    )
    return {
        "hourlyData": [
            {
                "hour": row.hour,
                "transaction_count": row.transaction_count,
                "total_revenue": float(row.total_revenue or 0),
            }
            for row in rows
        ]
    }


def sales_by_day(
    db: Session, user: User, start: datetime, end: datetime
) -> dict:
    local_sale_time = func.timezone("Asia/Bangkok", Sale.sale_date)
    sale_day = cast(local_sale_time, Date)
    rows = db.execute(
        select(
            sale_day.label("sale_day"),
            func.count(Sale.id).label("transaction_count"),
            func.sum(Sale.total_amount).label("total_revenue"),
        )
        .where(*_sale_filters(user, start, end))
        .group_by(sale_day)
        .order_by(sale_day)
    )
    return {
        "dailyData": [
            {
                "sale_day": row.sale_day,
                "transaction_count": row.transaction_count,
                "total_revenue": float(row.total_revenue or 0),
            }
            for row in rows
        ]
    }


def top_products(
    db: Session,
    user: User,
    start: datetime,
    end: datetime,
    limit: int,
) -> list[dict]:
    start_utc, end_utc = normalize_range(start, end)
    rows = db.execute(
        select(
            Product.name,
            Product.code,
            Product.image,
            func.sum(SaleItem.quantity).label("total_quantity"),
            func.sum(SaleItem.total_price).label("total_revenue"),
            func.count(SaleItem.id).label("sale_count"),
        )
        .join(SaleItem, SaleItem.product_id == Product.id)
        .join(Sale, Sale.id == SaleItem.sale_id)
        .where(
            Sale.user_id == user.id,
            Product.user_id == user.id,
            Sale.sale_date >= start_utc,
            Sale.sale_date <= end_utc,
        )
        .group_by(Product.id, Product.name, Product.code, Product.image)
        .order_by(func.sum(SaleItem.total_price).desc(), Product.id)
        .limit(limit)
    )
    return [
        {
            "name": row.name,
            "code": row.code,
            "image": row.image,
            "total_quantity": row.total_quantity,
            "total_revenue": float(row.total_revenue or 0),
            "sale_count": row.sale_count,
        }
        for row in rows
    ]


def customer_purchase_history(
    db: Session, user: User, limit: int
) -> list[dict]:
    rows = db.execute(
        select(
            Sale.customer_name,
            Sale.customer_phone,
            func.count(Sale.id).label("purchase_count"),
            func.sum(Sale.total_amount).label("total_spent"),
            func.max(Sale.sale_date).label("last_purchase_date"),
        )
        .where(Sale.user_id == user.id, Sale.customer_name.is_not(None))
        .group_by(Sale.customer_name, Sale.customer_phone)
        .order_by(func.sum(Sale.total_amount).desc(), Sale.customer_name)
        .limit(limit)
    )
    return [
        {
            "customer_name": row.customer_name,
            "customer_phone": row.customer_phone,
            "purchase_count": row.purchase_count,
            "total_spent": float(row.total_spent or 0),
            "last_purchase_date": row.last_purchase_date,
        }
        for row in rows
    ]


def inventory_movement(
    db: Session, user: User, start: datetime, end: datetime
) -> dict:
    start_utc, end_utc = normalize_range(start, end)
    rows = db.execute(
        select(
            Product.name,
            Product.code,
            func.sum(
                case(
                    (
                        Inventory.change_type == "SALE",
                        Inventory.stock_before - Inventory.stock_after,
                    ),
                    else_=0,
                )
            ).label("sold_quantity"),
            func.sum(
                case(
                    (
                        Inventory.change_type == "STOCK_IN",
                        Inventory.stock_after - Inventory.stock_before,
                    ),
                    else_=0,
                )
            ).label("received_quantity"),
            func.max(Inventory.created_at).label("last_updated"),
        )
        .join(Product, Product.id == Inventory.product_id)
        .where(
            Inventory.user_id == user.id,
            Product.user_id == user.id,
            Inventory.created_at >= start_utc,
            Inventory.created_at <= end_utc,
        )
        .group_by(Product.id, Product.name, Product.code)
        .order_by(
            func.sum(
                case(
                    (
                        Inventory.change_type == "SALE",
                        Inventory.stock_before - Inventory.stock_after,
                    ),
                    else_=0,
                )
            ).desc(),
            Product.id,
        )
    )
    return {
        "inventoryData": [
            {
                "name": row.name,
                "code": row.code,
                "sold_quantity": row.sold_quantity or 0,
                "received_quantity": row.received_quantity or 0,
                "last_updated": row.last_updated,
            }
            for row in rows
        ]
    }


def reorder_suggestions(db: Session, user: User) -> list[dict]:
    now = datetime.now(timezone.utc)
    recent_sales = (
        select(
            SaleItem.product_id.label("product_id"),
            func.sum(SaleItem.quantity).label("units_sold"),
        )
        .join(Sale, Sale.id == SaleItem.sale_id)
        .join(Product, Product.id == SaleItem.product_id)
        .where(
            Sale.user_id == user.id,
            Product.user_id == user.id,
            Sale.sale_date >= now - timedelta(days=30),
            Sale.sale_date <= now,
        )
        .group_by(SaleItem.product_id)
        .subquery()
    )
    average_daily_sales = (
        cast(func.coalesce(recent_sales.c.units_sold, 0), Float) / 30.0
    )
    days_until_out = case(
        (
            average_daily_sales > 0,
            cast(Product.quantity, Float) / average_daily_sales,
        ),
        else_=999.0,
    )
    rows = db.execute(
        select(
            Product.name,
            Product.code,
            Product.image,
            Product.quantity,
            Product.low_stock,
            Product.unit,
            average_daily_sales.label("avg_daily_sales"),
            days_until_out.label("days_until_out_of_stock"),
        )
        .outerjoin(recent_sales, recent_sales.c.product_id == Product.id)
        .where(
            Product.user_id == user.id,
            Product.quantity <= Product.low_stock * 1.5,
        )
        .order_by(days_until_out, Product.id)
    )
    return [
        {
            "name": row.name,
            "code": row.code,
            "image": row.image,
            "quantity": row.quantity,
            "low_stock": row.low_stock,
            "unit": row.unit,
            "avg_daily_sales": float(row.avg_daily_sales or 0),
            "days_until_out_of_stock": float(row.days_until_out_of_stock),
        }
        for row in rows
    ]


def domestic_export_sales(
    db: Session, user: User, start: datetime, end: datetime
) -> dict:
    local_sale_time = func.timezone("Asia/Bangkok", Sale.sale_date)
    sale_day = cast(local_sale_time, Date)
    domestic_phone = or_(
        Sale.customer_phone.is_(None),
        Sale.customer_phone.op("~")(r"^0[0-9]{9}$"),
    )
    export_phone = and_(
        Sale.customer_phone.is_not(None),
        ~Sale.customer_phone.op("~")(r"^0[0-9]{9}$"),
    )
    rows = db.execute(
        select(
            sale_day.label("sale_day"),
            func.sum(
                case((domestic_phone, Sale.total_amount), else_=0)
            ).label("domestic_revenue"),
            func.sum(case((export_phone, Sale.total_amount), else_=0)).label(
                "export_revenue"
            ),
            func.count(case((domestic_phone, Sale.id))).label("domestic_count"),
            func.count(case((export_phone, Sale.id))).label("export_count"),
        )
        .where(*_sale_filters(user, start, end))
        .group_by(sale_day)
        .order_by(sale_day)
    )
    return {
        "dailyData": [
            {
                "sale_day": row.sale_day,
                "domestic_revenue": float(row.domestic_revenue or 0),
                "export_revenue": float(row.export_revenue or 0),
                "domestic_count": row.domestic_count,
                "export_count": row.export_count,
            }
            for row in rows
        ]
    }


def revenue_projection(
    db: Session, user: User, start: datetime, end: datetime
) -> dict:
    start_utc, end_utc = normalize_range(start, end)
    local_sale_time = func.timezone("Asia/Bangkok", Sale.sale_date)
    sale_day = cast(local_sale_time, Date)
    historical_rows = db.execute(
        select(
            sale_day.label("period"),
            func.sum(Sale.total_amount).label("actual_revenue"),
        )
        .where(
            Sale.user_id == user.id,
            Sale.sale_date >= start_utc,
            Sale.sale_date <= end_utc,
        )
        .group_by(sale_day)
        .order_by(sale_day)
    )
    projection_start = end_utc - timedelta(days=30)
    projection_rows = db.execute(
        select(func.sum(Sale.total_amount).label("daily_revenue"))
        .where(
            Sale.user_id == user.id,
            Sale.sale_date >= projection_start,
            Sale.sale_date <= end_utc,
        )
        .group_by(sale_day)
    )
    daily_totals = [float(row.daily_revenue or 0) for row in projection_rows]
    return {
        "historicalData": [
            {
                "period": row.period,
                "actual_revenue": float(row.actual_revenue or 0),
            }
            for row in historical_rows
        ],
        "projectionAverage": (
            sum(daily_totals) / len(daily_totals) if daily_totals else 0.0
        ),
    }


def payment_methods(
    db: Session, user: User, start: datetime, end: datetime
) -> list[dict]:
    rows = db.execute(
        select(
            Sale.payment_method,
            func.count(Sale.id).label("transaction_count"),
            func.sum(Sale.total_amount).label("total_revenue"),
        )
        .where(*_sale_filters(user, start, end))
        .group_by(Sale.payment_method)
        .order_by(func.sum(Sale.total_amount).desc(), Sale.payment_method)
    )
    return [
        {
            "payment_method": row.payment_method,
            "transaction_count": row.transaction_count,
            "total_revenue": float(row.total_revenue or 0),
        }
        for row in rows
    ]


def category_performance(
    db: Session, user: User, start: datetime, end: datetime
) -> list[dict]:
    start_utc, end_utc = normalize_range(start, end)
    rows = db.execute(
        select(
            Product.category,
            func.sum(SaleItem.total_price).label("total_revenue"),
            func.sum(SaleItem.quantity).label("total_quantity"),
            func.count(func.distinct(Sale.id)).label("transaction_count"),
        )
        .join(SaleItem, SaleItem.product_id == Product.id)
        .join(Sale, Sale.id == SaleItem.sale_id)
        .where(
            Sale.user_id == user.id,
            Product.user_id == user.id,
            Product.category.is_not(None),
            Sale.sale_date >= start_utc,
            Sale.sale_date <= end_utc,
        )
        .group_by(Product.category)
        .order_by(func.sum(SaleItem.total_price).desc(), Product.category)
        .limit(8)
    )
    return [
        {
            "category": row.category,
            "total_revenue": float(row.total_revenue or 0),
            "total_quantity": row.total_quantity,
            "transaction_count": row.transaction_count,
        }
        for row in rows
    ]


def customer_segmentation(db: Session, user: User, limit: int) -> dict:
    customers = customer_purchase_history(db, user, limit)
    total_spent = sum(customer["total_spent"] for customer in customers)
    segments = {"highValue": 0, "mediumValue": 0, "lowValue": 0}
    for customer in customers:
        spent = customer["total_spent"]
        if spent >= 5000:
            segments["highValue"] += 1
        elif spent >= 1000:
            segments["mediumValue"] += 1
        else:
            segments["lowValue"] += 1
    count = len(customers)
    return {
        "segments": segments,
        "totalCustomers": count,
        "averageSpentPerCustomer": total_spent / count if count else 0.0,
        "totalRevenue": total_spent,
    }


def sales_trends(
    db: Session, user: User, start: datetime, end: datetime
) -> dict:
    start_utc, end_utc = normalize_range(start, end)
    current = sales_by_day(db, user, start_utc, end_utc)
    duration = end_utc - start_utc
    previous = sales_by_day(
        db, user, start_utc - duration, end_utc - duration
    )
    current_revenue = sum(
        row["total_revenue"] for row in current["dailyData"]
    )
    previous_revenue = sum(
        row["total_revenue"] for row in previous["dailyData"]
    )
    growth = (
        (current_revenue - previous_revenue) / previous_revenue * 100
        if previous_revenue
        else 0.0
    )
    return {
        "currentPeriodData": current,
        "previousPeriodData": previous,
        "currentRevenue": current_revenue,
        "previousRevenue": previous_revenue,
        "growthRate": growth,
    }


def dashboard(db: Session, user: User) -> dict:
    start, end = today_range()
    sales = sales_in_range(db, user, start, end)
    top = top_products(db, user, start, end, 5)
    low_stock = list(
        db.scalars(
            select(Product)
            .where(
                Product.user_id == user.id,
                Product.quantity <= Product.low_stock,
            )
            .order_by(Product.quantity, Product.name, Product.id)
        )
    )
    return {
        "today_total": sum(float(sale.total_amount) for sale in sales),
        "today_count": len(sales),
        "sales": sales,
        "top_products": top,
        "low_stock": low_stock,
    }
