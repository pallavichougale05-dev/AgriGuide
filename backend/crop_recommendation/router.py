from fastapi import APIRouter, HTTPException
import httpx
from pydantic import BaseModel, Field, model_validator

from . import climate
from .recommender import recommend_top5

router = APIRouter(prefix="/crop", tags=["crop"])

@router.get("/location-search")
async def search_crop_locations(query: str):
    query = query.strip()

    if len(query) < 2:
        return {"results": []}

    url = "https://geocoding-api.open-meteo.com/v1/search"

    params = {
        "name": query,
        "count": 10,
        "language": "en",
        "format": "json",
        "countryCode": "IN",
    }

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()
            data = response.json()

        raw_results = data.get("results") or []

        results = []

        for item in raw_results:
            if item.get("latitude") is None or item.get("longitude") is None:
                continue

            results.append({
                "name": item.get("name", ""),
                "latitude": item["latitude"],
                "longitude": item["longitude"],
                "country": item.get("country", "India"),
                "admin1": item.get("admin1", ""),
                "admin2": item.get("admin2", ""),
            })

        return {"results": results}

    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail="Location search service is temporarily unavailable.",
        ) from exc

class CropRequest(BaseModel):
    nitrogen: float = Field(..., ge=0, le=500)
    phosphorus: float = Field(..., ge=0, le=500)
    potassium: float = Field(..., ge=0, le=500)
    ph: float = Field(..., ge=0, le=14)

    # Normal use: the app sends the farm location, the server finds the yearly climate.
    latitude: float | None = Field(None, ge=-90, le=90)
    longitude: float | None = Field(None, ge=-180, le=180)

    # Alternative: send YEARLY values yourself (mean temperature, mean humidity, total rainfall).
    # Never send today's weather: the model was trained on yearly rainfall.
    temperature: float | None = Field(None, ge=-10, le=60)
    humidity: float | None = Field(None, ge=0, le=100)
    rainfall: float | None = Field(None, ge=0, le=6000)

    @model_validator(mode="after")
    def need_location_or_climate(self):
        has_location = self.latitude is not None and self.longitude is not None
        has_climate = None not in (self.temperature, self.humidity, self.rainfall)
        if not (has_location or has_climate):
            raise ValueError("Send latitude and longitude, or temperature, humidity and rainfall.")
        return self


@router.post("/recommend")
async def recommend(payload: CropRequest):
    if payload.latitude is not None and payload.longitude is not None:
        try:
            c = await climate.get_annual_climate(payload.latitude, payload.longitude)
        except climate.ClimateUnavailable:
            raise HTTPException(status_code=503, detail="Could not get the climate for this location right now. Please try again.")
        source = "open-meteo yearly history"
    else:
        c = {"temperature": payload.temperature, "humidity": payload.humidity, "rainfall": payload.rainfall}
        source = "sent by the app"
    try:
        recs = recommend_top5(payload.nitrogen, payload.phosphorus, payload.potassium,
                              c["temperature"], c["humidity"], payload.ph, c["rainfall"])
    except Exception:
        raise HTTPException(status_code=500, detail="Something went wrong while checking the recommendation. Please try again.")
    return {"recommendations": recs, "climate_used": {**c, "source": source}}
