from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

from app.config import Settings, get_settings
from app.routers.auth import router as auth_router
from app.routers.cart import router as cart_router
from app.routers.inventory import router as inventory_router
from app.routers.profile import router as profile_router
from app.routers.products import router as products_router
from app.routers.reports import router as reports_router
from app.routers.sales import router as sales_router


def create_app(settings: Settings | None = None) -> FastAPI:
    application_settings = settings or get_settings()
    engine = create_engine(application_settings.database_url, pool_pre_ping=True)

    @asynccontextmanager
    async def lifespan(_: FastAPI):
        yield
        engine.dispose()

    app = FastAPI(title="Jame API", version="0.1.0", lifespan=lifespan)
    app.state.settings = application_settings
    app.state.engine = engine
    app.include_router(auth_router, prefix="/api/v1")
    app.include_router(cart_router, prefix="/api/v1")
    app.include_router(products_router, prefix="/api/v1")
    app.include_router(inventory_router, prefix="/api/v1")
    app.include_router(profile_router, prefix="/api/v1")
    app.include_router(reports_router, prefix="/api/v1")
    app.include_router(sales_router, prefix="/api/v1")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=application_settings.allowed_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/health")
    def health() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/ready")
    def ready() -> dict[str, str]:
        try:
            with engine.connect() as connection:
                connection.execute(text("SELECT 1"))
        except SQLAlchemyError as error:
            raise HTTPException(
                status_code=503, detail="database unavailable"
            ) from error
        return {"status": "ok"}

    return app


app = create_app()
