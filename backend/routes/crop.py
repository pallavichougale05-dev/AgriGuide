
import asyncio

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field, model_validator
from starlette.concurrency import run_in_threadpool

from crop_recommendation import climate
from translation_service import translate_text
from .recommender import recommend_top5

router = APIRouter(prefix="/crop", tags=["crop"])


class CropRequest(BaseModel):
    nitrogen: float = Field(..., ge=0, le=500)
    phosphorus: float = Field(..., ge=0, le=500)
    potassium: float = Field(..., ge=0, le=500)
    ph: float = Field(..., ge=0, le=14)

    # Farm location: the server retrieves yearly climate data.
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)

    # Alternative: manually supplied yearly climate values.
    temperature: float | None = Field(None, ge=-10, le=60)
    humidity: float | None = Field(None, ge=0, le=100)
    rainfall: float | None = Field(None, ge=0, le=6000)

    @model_validator(mode="after")
    def need_location_or_climate(self):
        has_location = (
            self.latitude is not None
            and self.longitude is not None
        )
        has_climate = None not in (
            self.temperature,
            self.humidity,
            self.rainfall,
        )

        if not (has_location or has_climate):
            raise ValueError(
                "Send latitude and longitude, or "
                "temperature, humidity and rainfall."
            )

        return self


async def translate_crop_recommendations(recommendations, lang):
    """
    Translate crop names only.
    Preserve scores, varieties and all other model output.
    """

    if lang == "en":
        return recommendations

    async def translate_one(item):
        original_name = item["crop"]

        try:
            translated_name = await run_in_threadpool(
                translate_text,
                original_name,
                lang,
            )
        except Exception as error:
            print(f"Crop name translation failed: {error}")
            translated_name = original_name

        return {
            **item,
            "crop": translated_name or original_name,
        }

    return await asyncio.gather(
        *(translate_one(item) for item in recommendations)
    )


@router.post("/recommend")
async def recommend(
    payload: CropRequest,
    lang: str = Query(default="en", pattern="^(en|mr)$"),
):
    # STEP 1: Retrieve yearly climate.
    if payload.latitude is not None and payload.longitude is not None:
        try:
            c = await climate.get_annual_climate(
                payload.latitude,
                payload.longitude,
            )
        except climate.ClimateUnavailable:
            raise HTTPException(
                status_code=503,
                detail=(
                    "Could not get the climate for this location "
                    "right now. Please try again."
                ),
            )

        source = "open-meteo yearly history"

    else:
        c = {
            "temperature": payload.temperature,
            "humidity": payload.humidity,
            "rainfall": payload.rainfall,
        }
        source = "sent by the app"

    # STEP 2: Get recommendations from the existing trained model.
    try:
        recs = recommend_top5(
            payload.nitrogen,
            payload.phosphorus,
            payload.potassium,
            c["temperature"],
            c["humidity"],
            payload.ph,
            c["rainfall"],
        )
    except Exception as error:
        print(f"Crop recommendation error: {error}")
        raise HTTPException(
            status_code=500,
            detail=(
                "Something went wrong while checking the "
                "recommendation. Please try again."
            ),
        )

    # STEP 3: Translate crop names when Marathi is selected.
    recs = await translate_crop_recommendations(recs, lang)

    # STEP 4: Return the original recommendation structure.
    return {
        "recommendations": recs,
        "climate_used": {
            **c,
            "source": source,
        },
    }
