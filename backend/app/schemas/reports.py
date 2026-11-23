from datetime import date, datetime

from pydantic import BaseModel

from app.schemas.products import ProductResponse
from app.schemas.sales import SaleResponse


class SalesByHourRow(BaseModel):
    hour: int
    transaction_count: int
    total_revenue: float


class SalesByDayRow(BaseModel):
    sale_day: date
    transaction_count: int
    total_revenue: float


class TopProductRow(BaseModel):
    name: str
    code: str
    image: str | None
    total_quantity: int
    total_revenue: float
    sale_count: int


class CustomerPurchaseRow(BaseModel):
    customer_name: str
    customer_phone: str | None
    purchase_count: int
    total_spent: float
    last_purchase_date: datetime


class InventoryMovementRow(BaseModel):
    name: str
    code: str
    sold_quantity: int
    received_quantity: int
    last_updated: datetime


class ReorderSuggestionRow(BaseModel):
    name: str
    code: str
    image: str | None
    quantity: int
    low_stock: int
    unit: str
    avg_daily_sales: float
    days_until_out_of_stock: float


class PaymentMethodRow(BaseModel):
    payment_method: str
    transaction_count: int
    total_revenue: float


class CategoryPerformanceRow(BaseModel):
    category: str
    total_revenue: float
    total_quantity: int
    transaction_count: int


class DomesticExportRow(BaseModel):
    sale_day: date
    domestic_revenue: float
    export_revenue: float
    domestic_count: int
    export_count: int


class RevenueHistoryRow(BaseModel):
    period: date
    actual_revenue: float


class DashboardReport(BaseModel):
    today_total: float
    today_count: int
    sales: list[SaleResponse]
    top_products: list[TopProductRow]
    low_stock: list[ProductResponse]


class HourlySalesReport(BaseModel):
    hourlyData: list[SalesByHourRow]


class DailySalesReport(BaseModel):
    dailyData: list[SalesByDayRow]


class InventoryMovementReport(BaseModel):
    inventoryData: list[InventoryMovementRow]


class DomesticExportReport(BaseModel):
    dailyData: list[DomesticExportRow]


class RevenueProjectionReport(BaseModel):
    historicalData: list[RevenueHistoryRow]
    projectionAverage: float


class CustomerSegmentationReport(BaseModel):
    segments: dict[str, int]
    totalCustomers: int
    averageSpentPerCustomer: float
    totalRevenue: float


class SalesTrendsReport(BaseModel):
    currentPeriodData: DailySalesReport
    previousPeriodData: DailySalesReport
    currentRevenue: float
    previousRevenue: float
    growthRate: float
