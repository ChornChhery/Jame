from collections.abc import Generator

from fastapi import Request
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker


class Base(DeclarativeBase):
    pass


def get_db(request: Request) -> Generator[Session, None, None]:
    factory = sessionmaker(
        bind=request.app.state.engine,
        autoflush=False,
        expire_on_commit=False,
    )
    with factory() as session:
        yield session
