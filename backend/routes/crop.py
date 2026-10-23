from fastapi import APIRouter
from pydantic import BaseModel


# Creates the router for Crop Recommendation APIs.
router = APIRouter(
    prefix="/crop",
    tags=["Crop Recommendation"],
)


# Defines the farm information received from Flutter.
class CropRequest(BaseModel):
    nitrogen: float
    phosphorus: float
    potassium: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float


# Defines one crop recommendation returned to Flutter.
class CropRecommendation(BaseModel):
    crop: str
    variety: str
    score: float


# Returns the top five crop + variety recommendations.
def get_top_recommendations(data: CropRequest):
    # TEMPORARY INTEGRATION DATA.
    #
    # Replace only this function with your teammate's
    # trained-model logic when the model is ready.
    #
    # The Flutter application already expects this response structure:
    #
    # crop
    # variety
    # score
    #
    # No Flutter UI changes will be required when the
    # real model is connected.

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


# Creates the Crop Recommendation endpoint.
@router.post("/recommend")
def recommend_crop(data: CropRequest):
    # Gets the top five recommendations.
    recommendations = get_top_recommendations(data)

    # Returns a structured JSON response.
    return {
        "recommendations": recommendations,
    }