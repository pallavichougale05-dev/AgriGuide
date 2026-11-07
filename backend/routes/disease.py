from fastapi import APIRouter, File, UploadFile, Query

from translation_service import translate_text


router = APIRouter(
    prefix="/disease",
    tags=["Disease Detection"],
)

# TRANSLATION
def translate_disease_text(
    text: str,
    lang: str
) -> str:
    """
    Translate disease detection messages into the selected language.
    Supported languages:
    - en: English
    - mr: Marathi
    """

    if not text or lang == "en":
        return text

    try:
        return translate_text(
            text,
            target_language=lang
        )

    except Exception as error:
        print(f"Disease translation error: {error}")

        # Return the original message if translation fails.
        return text


# DISEASE DETECTION API

@router.post("/detect")
async def detect_disease(
    image: UploadFile = File(...),

    lang: str = Query(
        default="en",
        pattern="^(en|mr)$"
    )
):
    """
    Receive a crop image and return its upload status.
    The disease detection model will be integrated later.
    """

    # Read uploaded image
    image_bytes = await image.read()

    # VALIDATE IMAGE
    if not image_bytes:

        message = "No image was uploaded."

        return {
            "success": False,
            "message": translate_disease_text(
                message,
                lang
            )
        }
    
    # MODEL NOT INTEGRATED YET
    message = (
        "Image received successfully. "
        "Disease detection model is not trained yet."
    )

    return {
        "success": True,
        "model_ready": False,
        "message": translate_disease_text(
            message,
            lang
        ),
        "filename": image.filename,
        "content_type": image.content_type,
        "image_size": len(image_bytes)
    }