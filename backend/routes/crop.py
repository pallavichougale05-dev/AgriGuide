from fastapi import APIRouter, Query
from pydantic import BaseModel

# Import the existing translation service.
# This assumes translation_service.py is in the backend root.
from translation_service import translate_text


router = APIRouter(
    prefix="/crop",
    tags=["Crop Recommendation"],
)


class CropRequest(BaseModel):
    nitrogen: float
    phosphorus: float
    potassium: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float


class CropRecommendation(BaseModel):
    crop: str
    variety: str
    score: float


# Dynamically translate text returned by the model.
def translate_crop_text(text: str, lang: str) -> str:
    if not text or lang == "en":
        return text

    try:
        return translate_text(
            text,
            target_language=lang,
        )
    except Exception as error:
        print(f"Crop translation error: {error}")
        return text


# Temporary recommendations.
# Replace this function with your trained-model logic later.
def get_top_recommendations(data: CropRequest):
    return [
        {
            "crop": "Soybean",
            "variety": "Model Result",
            "score": 92.0,
        },
        {
            "crop": "Wheat",
            "variety": "Model Result",
            "score": 87.0,
        },
        {
            "crop": "Maize",
            "variety": "Model Result",
            "score": 84.0,
        },
        {
            "crop": "Cotton",
            "variety": "Model Result",
            "score": 80.0,
        },
        {
            "crop": "Jowar",
            "variety": "Model Result",
            "score": 76.0,
        },
    ]


@router.post("/recommend")
def recommend_crop(
    data: CropRequest,
    lang: str = Query(
        default="en",
        pattern="^(en|mr)$",
    ),
):
    recommendations = get_top_recommendations(data)

    translated_recommendations = []

    for recommendation in recommendations:
        translated_recommendations.append(
            {
                "crop": translate_crop_text(
                    recommendation["crop"],
                    lang,
                ),
                "variety": translate_crop_text(
                    recommendation["variety"],
                    lang,
                ),
                "score": recommendation["score"],
            }
        )

    return {
        "recommendations": translated_recommendations,
    }