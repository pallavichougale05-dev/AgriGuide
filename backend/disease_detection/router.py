
from fastapi import APIRouter, File, HTTPException, UploadFile, Query
from fastapi.concurrency import run_in_threadpool

from translation_service import translate_text
from . import image_utils
from .detector import detector

router = APIRouter(prefix="/disease", tags=["disease"])


def translate_result(value, lang):
    """Translate displayed text without changing prediction fields."""

    if lang == "en":
        return value

    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            if key in ("status", "kind"):
                result[key] = item
            else:
                result[key] = translate_result(item, lang)
        return result

    if isinstance(value, list):
        return [translate_result(item, lang) for item in value]

    if isinstance(value, str):
        try:
            return translate_text(value, target_language=lang)
        except Exception as error:
            print(f"Disease translation error: {error}")
            return value

    return value


@router.post("/detect")
async def detect_disease(
    image: UploadFile = File(...),
    lang: str = Query(default="en", pattern="^(en|mr)$")
):
    if not detector.ready:
        raise HTTPException(
            status_code=503,
            detail="Disease detection is not available right now. Please try again later."
        )

    data = await image.read(image_utils.MAX_BYTES + 1)

    try:
        result = await run_in_threadpool(detector.detect, data)

        if lang == "mr":
            result = await run_in_threadpool(
                translate_result, result, lang
            )

    except image_utils.BadImage as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    except Exception:
        raise HTTPException(
            status_code=500,
            detail="Something went wrong while checking the image. Please try again."
        )

    return result


@router.get("/status")
def disease_status():
    """Quick check that the models loaded."""
    return {
        "ready": detector.ready,
        "error": detector.error,
        "classes": len(detector.names) if detector.ready else 0
    }
