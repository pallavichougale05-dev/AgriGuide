from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models.diary import FarmDiary
from routes.auth import get_current_user


router = APIRouter(
    prefix="/diary",
    tags=["Farm Diary"],
)


# ============================================================
# REQUEST / RESPONSE MODELS
# ============================================================

class DiaryEntryRequest(BaseModel):
    date: datetime
    crop_field: str
    activity: str
    notes: str


class DiaryEntryResponse(BaseModel):
    id: int
    date: datetime
    crop_field: str
    activity: str
    notes: str

    class Config:
        from_attributes = True


# ============================================================
# CREATE DIARY ENTRY
# POST /diary
# ============================================================

@router.post(
    "",
    response_model=DiaryEntryResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_diary_entry(
    entry: DiaryEntryRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    new_entry = FarmDiary(
        user_id=current_user.id,
        date=entry.date,
        crop_field=entry.crop_field,
        activity=entry.activity,
        notes=entry.notes,
    )

    db.add(new_entry)
    db.commit()
    db.refresh(new_entry)

    return new_entry


# ============================================================
# GET ALL DIARY ENTRIES FOR CURRENT USER
# GET /diary
# ============================================================

@router.get(
    "",
    response_model=list[DiaryEntryResponse],
)
def get_diary_entries(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entries = (
        db.query(FarmDiary)
        .filter(FarmDiary.user_id == current_user.id)
        .order_by(FarmDiary.date.desc())
        .all()
    )

    return entries


# ============================================================
# GET ONE DIARY ENTRY
# GET /diary/{entry_id}
# ============================================================

@router.get(
    "/{entry_id}",
    response_model=DiaryEntryResponse,
)
def get_diary_entry(
    entry_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entry = (
        db.query(FarmDiary)
        .filter(
            FarmDiary.id == entry_id,
            FarmDiary.user_id == current_user.id,
        )
        .first()
    )

    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )

    return entry


# ============================================================
# UPDATE DIARY ENTRY
# PUT /diary/{entry_id}
# ============================================================

@router.put(
    "/{entry_id}",
    response_model=DiaryEntryResponse,
)
def update_diary_entry(
    entry_id: int,
    entry_data: DiaryEntryRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entry = (
        db.query(FarmDiary)
        .filter(
            FarmDiary.id == entry_id,
            FarmDiary.user_id == current_user.id,
        )
        .first()
    )

    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )

    entry.date = entry_data.date
    entry.crop_field = entry_data.crop_field
    entry.activity = entry_data.activity
    entry.notes = entry_data.notes

    db.commit()
    db.refresh(entry)

    return entry


# ============================================================
# DELETE DIARY ENTRY
# DELETE /diary/{entry_id}
# ============================================================

@router.delete(
    "/{entry_id}",
)
def delete_diary_entry(
    entry_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entry = (
        db.query(FarmDiary)
        .filter(
            FarmDiary.id == entry_id,
            FarmDiary.user_id == current_user.id,
        )
        .first()
    )

    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )

    db.delete(entry)
    db.commit()

    return {
        "message": "Diary entry deleted successfully",
    }