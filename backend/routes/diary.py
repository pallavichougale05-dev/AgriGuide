import logging
import re
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models.diary import FarmDiary
from routes.auth import get_current_user

import requests

logger = logging.getLogger("uvicorn.error")


router = APIRouter(
    prefix="/diary",
    tags=["Farm Diary"],
)


# ============================================================
# TRANSLATION FOR DISPLAY
# ============================================================
#
# The database always keeps exactly what the farmer typed.
# Translation happens only when entries are READ with
# ?lang=mr or ?lang=en, and nothing is written back.
#
#   lang=mr  English text  -> Marathi
#   lang=en  Marathi text  -> English
#   Text already in the requested language is left untouched.
#
# Order used for each text:
#   1. built-in word list (common crops and farm activities)
#   2. machine translation (MyMemory web service, via requests)
#   3. if that fails, the original text
# ============================================================

DEVANAGARI = re.compile(r"[\u0900-\u097F]")

EN_TO_MR = {
    # Activities
    "watering": "पाणी देणे",
    "irrigation": "सिंचन",
    "sowing": "पेरणी",
    "planting": "लागवड",
    "spraying": "फवारणी",
    "fertilizer": "खत देणे",
    "fertilizing": "खत देणे",
    "weeding": "निंदणी",
    "harvest": "काढणी",
    "harvesting": "काढणी",
    "ploughing": "नांगरणी",
    "plowing": "नांगरणी",
    "pruning": "छाटणी",
    # Crops
    "tomato": "टोमॅटो",
    "rice": "भात",
    "rice field": "भाताचे शेत",
    "wheat": "गहू",
    "wheat field": "गव्हाचे शेत",
    "corn": "मका",
    "corn field": "मक्याचे शेत",
    "maize": "मका",
    "onion": "कांदा",
    "sugarcane": "ऊस",
    "cotton": "कापूस",
    "soybean": "सोयाबीन",
    "jowar": "ज्वारी",
    "sorghum": "ज्वारी",
    "bajra": "बाजरी",
    "chickpea": "हरभरा",
    "gram": "हरभरा",
    "groundnut": "भुईमूग",
    "potato": "बटाटा",
    "grapes": "द्राक्षे",
    "pomegranate": "डाळिंब",
    "turmeric": "हळद",
    "tur": "तूर",
    "banana": "केळी",
    "mango": "आंबा",
}

MR_TO_EN = {}
for _english, _marathi in EN_TO_MR.items():
    MR_TO_EN.setdefault(_marathi, _english)

_translation_cache: dict[tuple[str, str], str] = {}

MAX_TRANSLATE_LENGTH = 2000

MYMEMORY_URL = "https://api.mymemory.translated.net/get"

# MyMemory accepts only short texts per request, so longer notes
# are sent in pieces of at most this many characters.
MYMEMORY_CHUNK_SIZE = 400


def split_for_service(text: str) -> list[str]:
    sentences = re.split(r"(?<=[.!?\u0964])\s+", text)

    chunks: list[str] = []
    current = ""

    for sentence in sentences:
        while len(sentence) > MYMEMORY_CHUNK_SIZE:
            if current:
                chunks.append(current)
                current = ""
            chunks.append(sentence[:MYMEMORY_CHUNK_SIZE])
            sentence = sentence[MYMEMORY_CHUNK_SIZE:]

        if current and len(current) + 1 + len(sentence) > MYMEMORY_CHUNK_SIZE:
            chunks.append(current)
            current = sentence
        else:
            current = f"{current} {sentence}".strip()

    if current:
        chunks.append(current)

    return chunks


def machine_translate(text: str, target: str) -> str:
    """English <-> Marathi through the MyMemory service.
    Raises an error if the service gives no usable answer."""
    source = "mr" if target == "en" else "en"

    translated_parts = []

    for part in split_for_service(text):
        response = requests.get(
            MYMEMORY_URL,
            params={
                "q": part,
                "langpair": f"{source}|{target}",
            },
            timeout=15,
        )
        response.raise_for_status()

        data = response.json()
        translated = (data.get("responseData") or {}).get(
            "translatedText", ""
        )

        # MyMemory reports problems (for example the daily limit)
        # in these fields instead of failing the HTTP request.
        if (
            str(data.get("responseStatus")) != "200"
            or not translated
            or "MYMEMORY WARNING" in translated.upper()
        ):
            raise RuntimeError(
                data.get("responseDetails")
                or translated
                or "Translation service returned no result"
            )

        translated_parts.append(translated)

    return " ".join(translated_parts)


def normalize_language(lang: str) -> str:
    return "mr" if (lang or "").lower().startswith("mr") else "en"


def translate_text(text: str, target: str) -> str:
    clean = (text or "").strip()

    if not clean:
        return text

    is_marathi = bool(DEVANAGARI.search(clean))

    # Already in the language being requested.
    if target == "mr" and is_marathi:
        return text

    if target == "en" and not is_marathi:
        return text

    key = (target, clean)

    cached = _translation_cache.get(key)
    if cached is not None:
        return cached

    result = None

    if target == "mr":
        result = EN_TO_MR.get(clean.lower())
    else:
        result = MR_TO_EN.get(clean)

    if result is None:
        if len(clean) > MAX_TRANSLATE_LENGTH:
            return text

        try:
            result = machine_translate(clean, target)
        except Exception as error:
            # Do not cache failures, so the next request can retry.
            logger.warning(
                "Diary translation failed (%r -> %s): %r",
                clean,
                target,
                error,
            )
            return text

        if not result:
            return text

    _translation_cache[key] = result

    return result


def warm_translations(texts, target: str) -> None:
    """Translate all different texts at the same time, so a long
    diary does not wait for one translation after another."""
    pending = {t for t in texts if t and t.strip()}

    if not pending:
        return

    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(lambda t: translate_text(t, target), pending))


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
# GET /diary?lang=en|mr
# ============================================================

@router.get(
    "",
    response_model=list[DiaryEntryResponse],
)
def get_diary_entries(
    lang: str = "en",
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    entries = (
        db.query(FarmDiary)
        .filter(FarmDiary.user_id == current_user.id)
        .order_by(FarmDiary.date.desc())
        .all()
    )

    target = normalize_language(lang)

    logger.info(
        "GET /diary lang=%s -> translating to %s (%d entries)",
        lang,
        target,
        len(entries),
    )

    warm_translations(
        [
            text
            for entry in entries
            for text in (entry.crop_field, entry.activity, entry.notes)
        ],
        target,
    )

    # Build new response objects. The database rows are not
    # modified, so the farmer's original text stays as saved.
    return [
        DiaryEntryResponse(
            id=entry.id,
            date=entry.date,
            crop_field=translate_text(entry.crop_field, target),
            activity=translate_text(entry.activity, target),
            notes=translate_text(entry.notes, target),
        )
        for entry in entries
    ]


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