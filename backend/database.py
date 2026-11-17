import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


# DATABASE CONFIGURATION

DATABASE_USER = "postgres"
DATABASE_HOST = "localhost"
DATABASE_PORT = "5432"
DATABASE_NAME = "agriguide"


# Read the PostgreSQL password from Windows environment variables.
DATABASE_PASSWORD = os.getenv("AGRIGUIDE_DB_PASSWORD")


if not DATABASE_PASSWORD:
    raise RuntimeError(
        "AGRIGUIDE_DB_PASSWORD environment variable is not set."
    )

# DATABASE URL

DATABASE_URL = (
    f"postgresql+pg8000://"
    f"{DATABASE_USER}:{DATABASE_PASSWORD}"
    f"@{DATABASE_HOST}:{DATABASE_PORT}"
    f"/{DATABASE_NAME}"
)

# SQLALCHEMY ENGINE
# The engine manages communication between Python and PostgreSQL.
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
)

# DATABASE SESSION

# Each database operation will use a Session created from this
# session factory.
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)

# BASE MODEL
# Future database models such as Farm Diary will inherit from this Base class.
Base = declarative_base()

# DATABASE SESSION DEPENDENCY

def get_db():
    """
    Provides a database session to FastAPI routes.
    The session is automatically closed after the API request.
    """

    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()