from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from database import Base


class FarmDiary(Base):
    __tablename__ = "farm_diary"

    id: Mapped[int] = mapped_column(
        Integer,
        primary_key=True,
        autoincrement=True,
    )

    # Each diary entry belongs to an authenticated farmer.
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id"),
        nullable=True,
        index=True,
    )

    date: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
    )

    crop_field: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    activity: Mapped[str] = mapped_column(
        String(150),
        nullable=False,
    )

    notes: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )