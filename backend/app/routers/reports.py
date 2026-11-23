from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.db import get_db
from app.dependencies import get_current_user
from app.models import Sale, User
from app.schemas.reports import (
    CategoryPerformanceRow,
    CustomerPurchaseRow,
    CustomerSegmentationReport,
    DailySalesReport,
    DashboardReport,
    DomesticExportReport,
    HourlySalesReport,
    InventoryMovementReport,
    PaymentMethodRow,
    RevenueProjectionReport,
    ReorderSuggestionRow,
    SalesTrendsReport,
    TopProductRow,
)
from app.schemas.sales import SaleResponse
from app.services import reports


router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/dashboard", response_model=DashboardReport)
def get_dashboard(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.dashboard(db, user)


@router.get("/sales", response_model=list[SaleResponse])
def get_sales(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Sale]:
    return reports.sales_in_range(db, user, start, end)


@router.get("/sales/hourly", response_model=HourlySalesReport)
def get_sales_by_hour(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.sales_by_hour(db, user, start, end)


@router.get("/sales/daily", response_model=DailySalesReport)
def get_sales_by_day(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.sales_by_day(db, user, start, end)


@router.get("/sales/trends", response_model=SalesTrendsReport)
def get_sales_trends(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.sales_trends(db, user, start, end)


@router.get("/products/top", response_model=list[TopProductRow])
def get_top_products(
    start: datetime,
    end: datetime,
    limit: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[dict]:
    return reports.top_products(db, user, start, end, limit)


@router.get(
    "/customers/purchase-history",
    response_model=list[CustomerPurchaseRow],
)
def get_customer_purchase_history(
    limit: int = Query(default=50, ge=1, le=100),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[dict]:
    return reports.customer_purchase_history(db, user, limit)


@router.get("/inventory/movement", response_model=InventoryMovementReport)
def get_inventory_movement(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.inventory_movement(db, user, start, end)


@router.get(
    "/inventory/reorder-suggestions",
    response_model=list[ReorderSuggestionRow],
)
def get_reorder_suggestions(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[dict]:
    return reports.reorder_suggestions(db, user)


@router.get("/products/performance", response_model=list[TopProductRow])
def get_product_performance(
    start: datetime,
    end: datetime,
    limit: int = Query(default=20, ge=1, le=100),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[dict]:
    return reports.top_products(db, user, start, end, limit)


@router.get(
    "/customers/segmentation",
    response_model=CustomerSegmentationReport,
)
def get_customer_segmentation(
    limit: int = Query(default=100, ge=1, le=100),
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.customer_segmentation(db, user, limit)


@router.get("/revenue-projection", response_model=RevenueProjectionReport)
def get_revenue_projection(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.revenue_projection(db, user, start, end)


@router.get("/payment-methods", response_model=list[PaymentMethodRow])
def get_payment_methods(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[dict]:
    return reports.payment_methods(db, user, start, end)


@router.get("/categories", response_model=list[CategoryPerformanceRow])
def get_categories(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[dict]:
    return reports.category_performance(db, user, start, end)


@router.get("/domestic-export-sales", response_model=DomesticExportReport)
def get_domestic_export_sales(
    start: datetime,
    end: datetime,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    return reports.domestic_export_sales(db, user, start, end)
